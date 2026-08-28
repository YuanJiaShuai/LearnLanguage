#!/usr/bin/env python3
"""Rebuild word-list examples from macOS Dictionary lookups."""

from __future__ import annotations

import argparse
import json
import sqlite3
import subprocess
import sys
import tempfile
from pathlib import Path


OLD_SOURCE = "assistant-generated"
NEW_SOURCE = "system-dictionary"
ROOT = Path(__file__).resolve().parents[1]
RESOURCE_DB = ROOT / "LearnLanguage/Resources/InitialDicts/LearnLanguage.db"
LOCAL_DB = Path.home() / "Library/Containers/com.ruijia.LearnLanguage/Data/Documents/LearnLanguage.db"
DATABASES = (RESOURCE_DB, LOCAL_DB)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Rebuild examples for a word list using macOS Dictionary lookups."
    )
    group = parser.add_mutually_exclusive_group()
    group.add_argument(
        "--word-list-id",
        type=int,
        help="Target word_lists.id. Defaults to 139 (中考核心词).",
    )
    group.add_argument(
        "--all-word-lists",
        action="store_true",
        help="Rebuild examples for every unique word in the database.",
    )
    return parser.parse_args()


def load_word_list_name(db_path: Path, word_list_id: int) -> str:
    with sqlite3.connect(db_path) as connection:
        row = connection.execute(
            "SELECT name FROM word_lists WHERE id = ?",
            (word_list_id,),
        ).fetchone()
    if row is None:
        raise ValueError(f"word list not found: {word_list_id}")
    return str(row[0])


def lookup_word(word: str) -> str:
    for line in word.splitlines():
        cleaned = line.strip()
        if cleaned:
            return cleaned
    return word.strip()


def load_words(db_path: Path, word_list_id: int) -> list[str]:
    with sqlite3.connect(db_path) as connection:
        rows = connection.execute(
            """
            SELECT trim(word)
            FROM words
            WHERE word_list_id = ?
            GROUP BY lower(trim(word))
            ORDER BY min(id)
            """,
            (word_list_id,),
        ).fetchall()
    return [row[0] for row in rows if row[0]]


def load_all_words(db_path: Path) -> list[str]:
    with sqlite3.connect(db_path) as connection:
        rows = connection.execute(
            """
            SELECT trim(word)
            FROM words
            GROUP BY lower(trim(word))
            ORDER BY min(id)
            """
        ).fetchall()
    return [row[0] for row in rows if row[0]]


def compile_exporter(output_path: Path) -> None:
    command = [
        "swiftc",
        str(ROOT / "Tools/LLLoggerToolStub.swift"),
        str(ROOT / "LearnLanguage/Base/Utils/LLSystemDictionaryLookupTool.swift"),
        str(ROOT / "Tools/export_system_dictionary_examples.swift"),
        "-o",
        str(output_path),
    ]
    subprocess.run(command, check=True)


def export_examples(words: list[str], executable: Path) -> dict[str, list[dict[str, str | None]]]:
    process = subprocess.run(
        [str(executable)],
        input="\n".join(words) + "\n",
        text=True,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
        check=True,
    )

    examples_by_word: dict[str, list[dict[str, str | None]]] = {}
    for line in process.stdout.splitlines():
        if not line.strip():
            continue
        payload = json.loads(line)
        examples_by_word[payload["word"]] = payload["examples"]
    return examples_by_word


def export_and_select_rows(
    words: list[str],
    executable: Path,
) -> tuple[list[tuple[str, str, str, int, int, str]], int]:
    process = subprocess.Popen(
        [str(executable)],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=sys.stderr,
        text=True,
    )
    assert process.stdin is not None
    assert process.stdout is not None

    process.stdin.write(json.dumps(words, ensure_ascii=False))
    process.stdin.close()

    rows: list[tuple[str, str, str, int, int, str]] = []
    covered_words = 0

    for raw_line in process.stdout:
        line = raw_line.strip()
        if not line:
            continue
        payload = json.loads(line)
        word = str(payload["word"])
        chosen = selected_examples(payload.get("examples", []))
        if chosen:
            covered_words += 1
        for level, example in enumerate(chosen, start=1):
            rows.append((
                word,
                str(example["sentenceEn"]),
                str(example["sentenceCn"]),
                0,
                level,
                NEW_SOURCE,
            ))

    return_code = process.wait()
    if return_code != 0:
        raise subprocess.CalledProcessError(return_code, [str(executable)])

    return rows, covered_words


def selected_examples(examples: list[dict[str, str | None]]) -> list[dict[str, str | None]]:
    unique: list[dict[str, str | None]] = []
    seen: set[str] = set()
    for example in examples:
        sentence_en = " ".join((example.get("sentenceEn") or "").split())
        sentence_cn = " ".join((example.get("sentenceCn") or "").split())
        if not sentence_en or not sentence_cn:
            continue
        key = sentence_en.lower()
        if key in seen:
            continue
        seen.add(key)
        unique.append({"sentenceEn": sentence_en, "sentenceCn": sentence_cn})

    unique.sort(key=lambda item: (len(item["sentenceEn"]), item["sentenceEn"].lower()))
    if len(unique) <= 4:
        return unique

    indexes = [round((len(unique) - 1) * offset / 3) for offset in range(4)]
    chosen: list[dict[str, str | None]] = []
    used: set[int] = set()
    for index in indexes:
        while index in used and index + 1 < len(unique):
            index += 1
        if index not in used:
            used.add(index)
            chosen.append(unique[index])
    return chosen[:4]


def seed_target_words(connection: sqlite3.Connection, words: list[str]) -> None:
    connection.execute("DROP TABLE IF EXISTS target_words")
    connection.execute("CREATE TEMP TABLE target_words(word_text TEXT PRIMARY KEY) WITHOUT ROWID")
    batch_size = 2000
    for index in range(0, len(words), batch_size):
        connection.executemany(
            "INSERT INTO target_words(word_text) VALUES (?)",
            ((word,) for word in words[index:index + batch_size]),
        )


def rebuild_database(
    db_path: Path,
    words: list[str],
    rows: list[tuple[str, str, str, int, int, str]],
) -> int:
    with sqlite3.connect(db_path) as connection:
        connection.execute("PRAGMA journal_mode=WAL")
        seed_target_words(connection, words)
        connection.execute(
            """
            DELETE FROM word_examples
            WHERE source IN (?, ?)
            AND lower(trim(word_text)) IN (SELECT word_text FROM target_words)
            """,
            [OLD_SOURCE, NEW_SOURCE],
        )
        connection.executemany(
            """
            INSERT INTO word_examples
                (word_text, sentence_en, sentence_cn, heat, difficulty_level, source)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            rows,
        )
        connection.commit()
        connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")

    return len(rows)


def main() -> None:
    args = parse_args()
    if args.all_word_lists:
        words = load_all_words(LOCAL_DB)
        label = f"all unique words ({len(words)})"
    else:
        word_list_id = args.word_list_id or 139
        word_list_name = load_word_list_name(LOCAL_DB, word_list_id)
        words = load_words(LOCAL_DB, word_list_id)
        label = f"word list {word_list_id} ({word_list_name})"

    print(f"loaded {len(words)} unique words from {label}", file=sys.stderr)

    with tempfile.TemporaryDirectory() as temp_dir:
        executable = Path(temp_dir) / "dictionary_example_exporter"
        compile_exporter(executable)
        rows, covered_words = export_and_select_rows(words, executable)

    for db_path in DATABASES:
        inserted = rebuild_database(db_path, words, rows)
        print(f"{db_path}: inserted {inserted} examples for {covered_words} words")

    zero_count = len(words) - covered_words
    print(f"words without system dictionary examples: {zero_count}")


if __name__ == "__main__":
    main()
