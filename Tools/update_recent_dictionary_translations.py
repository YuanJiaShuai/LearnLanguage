#!/usr/bin/env python3
"""Update translations for the two recently studied word lists from macOS Dictionary."""

from __future__ import annotations

import argparse
import csv
import json
import shutil
import sqlite3
import subprocess
import sys
import tempfile
from datetime import datetime
from pathlib import Path
from typing import Any


ROOT = Path(__file__).resolve().parents[1]
LOCAL_DB = Path.home() / "Library/Containers/com.ruijia.LearnLanguage/Data/Documents/LearnLanguage.db"
WORD_LIST_IDS = (139, 1)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--apply", action="store_true", help="Write accepted translations to the database.")
    parser.add_argument("--limit", type=int, help="Limit rows for a fast preview.")
    return parser.parse_args()


def load_rows(limit: int | None) -> list[dict[str, Any]]:
    sql = """
        SELECT id, word_list_id AS wordListId, word, translation AS currentTranslation
        FROM words
        WHERE word_list_id IN (?, ?)
        ORDER BY word_list_id, id
    """
    params: list[Any] = list(WORD_LIST_IDS)
    if limit is not None:
        sql += " LIMIT ?"
        params.append(limit)

    with sqlite3.connect(LOCAL_DB) as connection:
        connection.row_factory = sqlite3.Row
        return [dict(row) for row in connection.execute(sql, params)]


def compile_exporter(output_path: Path) -> None:
    subprocess.run(
        [
            "swiftc",
            "-parse-as-library",
            str(ROOT / "Tools/export_system_dictionary_translations.swift"),
            "-o",
            str(output_path),
        ],
        check=True,
    )


def export_candidates(rows: list[dict[str, Any]], executable: Path) -> list[dict[str, Any]]:
    process = subprocess.Popen(
        [str(executable)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
        text=True,
    )
    assert process.stdin is not None
    assert process.stdout is not None

    process.stdin.write(json.dumps(rows, ensure_ascii=False))
    process.stdin.close()

    candidates: list[dict[str, Any]] = []
    for raw_line in process.stdout:
        line = raw_line.strip()
        if line:
            candidates.append(json.loads(line))

    return_code = process.wait()
    if return_code != 0:
        raise subprocess.CalledProcessError(return_code, [str(executable)])

    return candidates


def accepted_candidates(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    accepted: list[dict[str, Any]] = []
    for candidate in candidates:
        new_translation = normalize(candidate.get("newTranslation") or "")
        old_translation = normalize(candidate.get("currentTranslation") or "")
        if candidate.get("status") != "ok":
            continue
        if not new_translation or new_translation == old_translation:
            continue
        if looks_too_noisy(new_translation):
            continue
        candidate["newTranslation"] = new_translation
        accepted.append(candidate)
    return accepted


def normalize(value: str) -> str:
    return " ".join(value.replace("\u00a0", " ").split()).strip()


def looks_too_noisy(value: str) -> bool:
    blocked = [
        "牛津搭配词典",
        "更多例句",
        "同义词辨析",
        "词源",
        "点击查看",
        "源自",
        "中古英语",
        "古英语",
    ]
    return any(fragment in value for fragment in blocked)


def write_preview(candidates: list[dict[str, Any]], accepted: list[dict[str, Any]]) -> tuple[Path, Path]:
    output_dir = ROOT / "Tools/generated"
    output_dir.mkdir(exist_ok=True)
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    preview_path = output_dir / f"dictionary_translation_preview_{timestamp}.tsv"
    rejected_path = output_dir / f"dictionary_translation_rejected_{timestamp}.tsv"

    with preview_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["id", "word_list_id", "word", "old_translation", "new_translation"])
        for candidate in accepted:
            writer.writerow([
                candidate["id"],
                candidate["wordListId"],
                candidate["word"],
                candidate["currentTranslation"],
                candidate["newTranslation"],
            ])

    with rejected_path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.writer(handle, delimiter="\t")
        writer.writerow(["id", "word_list_id", "word", "status", "old_translation", "candidate"])
        for candidate in candidates:
            if candidate in accepted:
                continue
            writer.writerow([
                candidate["id"],
                candidate["wordListId"],
                candidate["word"],
                candidate.get("status"),
                candidate["currentTranslation"],
                candidate.get("newTranslation") or "",
            ])

    return preview_path, rejected_path


def backup_database() -> Path:
    backup_path = LOCAL_DB.with_name(
        LOCAL_DB.name + ".backup-before-translation-update-" + datetime.now().strftime("%Y%m%d-%H%M%S")
    )
    shutil.copy2(LOCAL_DB, backup_path)
    return backup_path


def apply_updates(accepted: list[dict[str, Any]]) -> None:
    with sqlite3.connect(LOCAL_DB) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        connection.executemany(
            "UPDATE words SET translation = ? WHERE id = ? AND word_list_id = ?",
            (
                (candidate["newTranslation"], candidate["id"], candidate["wordListId"])
                for candidate in accepted
            ),
        )
        connection.commit()
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")


def print_samples(accepted: list[dict[str, Any]]) -> None:
    for candidate in accepted[:30]:
        print(
            f'{candidate["wordListId"]}\t{candidate["word"]}\t'
            f'{candidate["currentTranslation"]}\t=>\t{candidate["newTranslation"]}'
        )


def main() -> None:
    args = parse_args()
    rows = load_rows(args.limit)
    print(f"loaded {len(rows)} rows from {LOCAL_DB}", file=sys.stderr)

    with tempfile.TemporaryDirectory() as temp_dir:
        executable = Path(temp_dir) / "dictionary_translation_exporter"
        compile_exporter(executable)
        candidates = export_candidates(rows, executable)

    accepted = accepted_candidates(candidates)
    preview_path, rejected_path = write_preview(candidates, accepted)

    status_counts: dict[str, int] = {}
    for candidate in candidates:
        status = str(candidate.get("status"))
        status_counts[status] = status_counts.get(status, 0) + 1

    print(f"status_counts={status_counts}")
    print(f"accepted={len(accepted)}")
    print(f"preview={preview_path}")
    print(f"rejected={rejected_path}")
    print_samples(accepted)

    if args.apply:
        backup_path = backup_database()
        apply_updates(accepted)
        print(f"backup={backup_path}")
        print(f"updated={len(accepted)}")
    else:
        print("dry_run=true")


if __name__ == "__main__":
    main()
