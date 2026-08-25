#!/usr/bin/env python3
"""Generate the four offline example levels for word list 139.

This script intentionally has no network or model dependency. It creates
predictable, review-friendly sentences and writes them into both SQLite
databases used by the app.
"""

from __future__ import annotations

import argparse
import re
import sqlite3
from pathlib import Path
from typing import Iterable


WORD_LIST_ID = 139
SOURCE = "assistant-generated"
LEVELS = (1, 2, 3, 4)

DEFAULT_DATABASES = (
    Path(__file__).resolve().parents[1]
    / "LearnLanguage/Resources/InitialDicts/LearnLanguage.db",
    Path.home()
    / "Library/Containers/com.ruijia.LearnLanguage/Data/Documents/LearnLanguage.db",
)

CONJUNCTIONS = {
    "and",
    "as",
    "although",
    "because",
    "before",
    "but",
    "if",
    "nor",
    "or",
    "since",
    "so",
    "than",
    "though",
    "unless",
    "until",
    "when",
    "while",
    "yet",
}

PREPOSITIONS = {
    "about",
    "above",
    "across",
    "after",
    "against",
    "along",
    "among",
    "around",
    "at",
    "behind",
    "below",
    "beneath",
    "beside",
    "between",
    "beyond",
    "by",
    "despite",
    "during",
    "except",
    "for",
    "from",
    "in",
    "inside",
    "into",
    "near",
    "of",
    "off",
    "on",
    "onto",
    "over",
    "through",
    "to",
    "toward",
    "under",
    "until",
    "upon",
    "with",
    "within",
    "without",
}

FUNCTION_WORDS = {
    "a",
    "an",
    "the",
    "am",
    "are",
    "be",
    "been",
    "being",
    "can",
    "could",
    "did",
    "do",
    "does",
    "had",
    "has",
    "have",
    "he",
    "her",
    "hers",
    "him",
    "his",
    "how",
    "i",
    "it",
    "its",
    "me",
    "might",
    "must",
    "my",
    "our",
    "ours",
    "she",
    "should",
    "that",
    "their",
    "theirs",
    "them",
    "these",
    "they",
    "this",
    "those",
    "us",
    "was",
    "we",
    "were",
    "what",
    "which",
    "who",
    "whom",
    "whose",
    "will",
    "would",
    "you",
    "your",
    "yours",
}

SPECIAL_CONJUNCTIONS = {
    "and": (
        ("Tom read the book, and Mia wrote the notes.", "汤姆读了这本书，米娅做了笔记。"),
        ("I wanted to leave, and my friend decided to stay.", "我想离开，而我的朋友决定留下。"),
        ("The lesson was short, and everyone still had time to ask questions.", "课程虽然很短，但每个人仍有时间提问。"),
        ("The team changed its plan, and the coach explained why the new choice was better.", "团队改变了计划，教练解释了为什么新选择更好。"),
    ),
    "but": (
        ("I was tired, but I finished my homework.", "我很累，但还是完成了作业。"),
        ("The road was narrow, but the driver moved slowly and safely.", "道路很窄，但司机缓慢而安全地行驶。"),
        ("The answer looked simple, but the question required careful reading.", "答案看起来很简单，但题目需要仔细阅读。"),
        ("The plan was attractive, but the team rejected it after examining the possible risks.", "这个计划很有吸引力，但团队分析可能的风险后否定了它。"),
    ),
    "because": (
        ("I stayed home because it was raining.", "因为下雨了，所以我待在家里。"),
        ("She took the bus because the station was far away.", "因为车站很远，所以她乘了公交车。"),
        ("We changed the schedule because several students had an important test.", "因为几名学生有重要考试，我们调整了时间表。"),
        ("The project was delayed because the team had to solve a problem that nobody had expected.", "项目延期了，因为团队必须解决一个没人预料到的问题。"),
    ),
    "if": (
        ("If you work hard, you can improve.", "如果你努力学习，就能进步。"),
        ("If the weather is fine, we will walk to school.", "如果天气好，我们就走路去学校。"),
        ("If you check the details carefully, you will find the mistake.", "如果你仔细检查细节，就会发现错误。"),
        ("If the evidence remains incomplete, the researchers will wait before making a final conclusion.", "如果证据仍不完整，研究人员会在下最终结论前继续等待。"),
    ),
    "although": (
        ("Although it was cold, we went outside.", "虽然天气很冷，但我们还是出去了。"),
        ("Although the task was difficult, she did not give up.", "虽然任务很难，但她没有放弃。"),
        ("Although the result was surprising, the teacher explained it clearly.", "虽然结果令人惊讶，但老师解释得很清楚。"),
        ("Although the proposal seemed practical, the committee asked for more evidence before approving it.", "虽然这个提议看起来很实际，但委员会要求更多证据后才批准。"),
    ),
    "when": (
        ("Call me when you arrive.", "你到了以后给我打电话。"),
        ("When the bell rang, the students opened their books.", "铃响时，学生们打开了书。"),
        ("When I read the article again, I noticed an important detail.", "我再次阅读文章时，注意到了一个重要细节。"),
        ("When the situation changed unexpectedly, the teacher showed us how to remain calm and make a careful choice.", "情况突然变化时，老师向我们展示了如何保持冷静并作出谨慎选择。"),
    ),
    "while": (
        ("She listened while I explained the plan.", "我解释计划时，她在认真听。"),
        ("While the soup was cooking, he set the table.", "汤在煮的时候，他摆好了餐桌。"),
        ("While some students preferred the first idea, others supported a different solution.", "一些学生更喜欢第一个想法，而另一些学生支持不同的解决方案。"),
        ("While the experiment was running, the scientists recorded every change so that they could compare the results later.", "实验进行时，科学家记录了每一处变化，以便之后比较结果。"),
    ),
}

SPECIAL_PREPOSITIONS = {
    "at": (
        ("We met at the station.", "我们在车站见面。"),
        ("She arrived at school before eight o'clock.", "她八点前到达了学校。"),
        ("At the end of the lesson, everyone checked the answers together.", "课程结束时，大家一起检查了答案。"),
        ("At a difficult moment, the captain stayed calm and helped the whole team choose the safest way forward.", "在困难时刻，队长保持冷静，帮助整个团队选择最安全的前进方式。"),
    ),
    "in": (
        ("The keys are in the drawer.", "钥匙在抽屉里。"),
        ("She lives in a small town near the sea.", "她住在海边附近的一个小镇。"),
        ("In the report, the writer describes how the local community solved the problem.", "报告中，作者描述了当地社区如何解决这个问题。"),
        ("In a rapidly changing world, students need to learn how to find reliable information and use it wisely.", "在快速变化的世界里，学生需要学会寻找可靠信息并明智地使用它。"),
    ),
    "on": (
        ("The book is on the desk.", "书在桌子上。"),
        ("We watched a program on television last night.", "我们昨晚在电视上看了一个节目。"),
        ("The article on environmental protection gave us several useful ideas.", "这篇关于环境保护的文章给了我们一些有用的想法。"),
        ("The decision on the new project will depend on whether the school can provide enough time and support.", "新项目的决定取决于学校是否能提供足够的时间和支持。"),
    ),
    "for": (
        ("This gift is for my sister.", "这份礼物是给我姐姐的。"),
        ("We waited for the bus outside the library.", "我们在图书馆外等公交车。"),
        ("The young athlete trained for several months before the competition.", "这名年轻运动员在比赛前训练了几个月。"),
        ("The program was designed for students who need extra practice but cannot attend another class after school.", "这个项目是为需要额外练习、但放学后无法参加另一节课的学生设计的。"),
    ),
    "from": (
        ("The letter came from my teacher.", "这封信来自我的老师。"),
        ("We could see the mountains from the window.", "我们从窗户可以看到群山。"),
        ("The information from the report helped us understand the situation.", "报告中的信息帮助我们理解了情况。"),
        ("Evidence from several different sources allowed the researchers to compare the results more fairly.", "来自多个不同来源的证据让研究人员能够更公平地比较结果。"),
    ),
    "to": (
        ("We walked to the library.", "我们走去了图书馆。"),
        ("She gave the note to her friend before class.", "她在课前把便条交给了朋友。"),
        ("The school plans to add more trees to the playground next year.", "学校计划明年在操场上增加更多树木。"),
        ("The new rule is intended to give every student a fair chance to take part in the activity.", "这项新规定旨在让每个学生都有公平的机会参加活动。"),
    ),
    "with": (
        ("She went with her friend.", "她和朋友一起去了。"),
        ("He opened the box with a small key.", "他用一把小钥匙打开了盒子。"),
        ("The students worked with the teacher to prepare a short performance.", "学生们和老师一起准备了一场短表演。"),
        ("The engineers solved the problem with a simple change that reduced both cost and energy use.", "工程师通过一个简单的改动解决了问题，同时降低了成本和能源使用。"),
    ),
    "about": (
        ("We talked about the plan.", "我们谈论了这个计划。"),
        ("The book is about a girl who travels around the world.", "这本书讲的是一个环游世界的女孩。"),
        ("The students asked several questions about how the machine worked.", "学生们询问了几个关于这台机器如何工作的​问题。"),
        ("The documentary raises important questions about how modern technology may change the way people live and work.", "这部纪录片提出了现代技术可能如何改变人们生活和工作的方式等重要问题。"),
    ),
}


def clean_meaning(translation: str, word: str) -> str:
    text = re.sub(
        r"\b(?:adj|adv|n|v|vt|vi|prep|pron|conj|num|art|aux|int|interj|abbr)\.\s*",
        "",
        translation,
        flags=re.I,
    )
    text = re.sub(r"[\(（\[][^)\]）]*[\)\]）]", "", text)
    text = re.split(r"[;；\n]", text, maxsplit=1)[0]
    text = re.sub(r"\s+", " ", text).strip(" ，,。")
    return text[:24] if text else word


def word_kind(word: str, translation: str) -> str:
    lower = word.lower()
    if lower in CONJUNCTIONS:
        return "conjunction"
    if lower in PREPOSITIONS:
        return "preposition"
    if lower in FUNCTION_WORDS:
        return "function"
    if lower in {
        "first",
        "second",
        "third",
        "fourth",
        "fifth",
        "sixth",
        "seventh",
        "eighth",
        "ninth",
        "tenth",
    } or "第" in translation:
        return "number"

    # The first part of the dictionary entry is the primary sense. This
    # avoids treating a noun such as "location" as an adjective just because
    # a secondary sense also lists an adjective form.
    first_part = re.split(r"[;；\n]", translation, maxsplit=1)[0]
    marker = re.search(
        r"\b(?:adj|adv|n|v|vt|vi|prep|pron|conj|num|art|aux|int|interj|abbr)\.",
        first_part,
        re.I,
    )
    if marker:
        token = marker.group(0).lower()
        if token == "adv.":
            return "adverb"
        if token == "adj.":
            return "adjective"
        if token in {"v.", "vt.", "vi."}:
            if "过去分词" in first_part or "过去式" in first_part or "现在分词" in first_part:
                return "function"
            return "verb"
        if token in {"pron.", "conj.", "prep.", "art.", "aux.", "int.", "interj.", "abbr."}:
            return "function"
    return "noun"


def generated_examples(word: str, translation: str) -> list[tuple[int, str, str]]:
    word = word.strip()
    lower = word.lower()
    meaning = clean_meaning(translation, word)
    kind = word_kind(word, translation)

    if lower in SPECIAL_CONJUNCTIONS:
        pairs = SPECIAL_CONJUNCTIONS[lower]
    elif lower in SPECIAL_PREPOSITIONS:
        pairs = SPECIAL_PREPOSITIONS[lower]
    elif kind == "number":
        if re.search(r"(first|second|third|fourth|fifth|sixth|seventh|eighth|ninth|tenth|第)", lower + translation, re.I):
            ordinal_meaning = meaning[1:] if meaning.startswith("第") else meaning
            pairs = (
                (f"She finished {word} in the race.", f"她在比赛中获得了第{ordinal_meaning}名。"),
                (f"He came {word} after a very close contest.", f"经过激烈竞争，他获得了第{ordinal_meaning}名。"),
                (f"The runner held {word} place until the final turn.", f"这名跑步者一直保持第{ordinal_meaning}名，直到最后一个弯道。"),
                (f"After reviewing the results, the judges confirmed that she had finished {word} among the strongest competitors.", f"评委查看结果后确认，她在最强的竞争者中获得了第{ordinal_meaning}名。"),
            )
        else:
            pairs = (
                (f"There are {word} students in the classroom.", f"教室里有{meaning}名学生。"),
                (f"The teacher gave {word} examples before the test.", f"老师在考试前给了{meaning}个例子。"),
                (f"The survey received answers from {word} students in our school.", f"这项调查收到了学校{meaning}名学生的回答。"),
                (f"The report shows that {word} students took part in the activity, although the final number may change.", f"报告显示有{meaning}名学生参加了活动，不过最终人数可能会变化。"),
            )
    elif kind == "verb":
        if lower in {"be", "am", "is", "are", "was", "were", "been", "being", "have", "has", "had", "do", "does", "did", "can", "could", "may", "might", "must", "will", "would", "should"}:
            pairs = (
                (f"The word \"{word}\" is common in English.", f"“{word}”这个词在英语中很常见。"),
                (f"I wrote down \"{word}\" after the teacher explained its meaning.", f"老师解释含义后，我记下了“{word}”。"),
                (f"When the sentence uses \"{word}\", the surrounding words help us understand the grammar.", f"句子使用“{word}”时，周围的词语能帮助我们理解语法。"),
                (f"Although \"{word}\" looks familiar, its exact meaning still depends on the sentence in which it appears.", f"虽然“{word}”看起来很熟悉，但它的确切含义仍取决于所在的句子。"),
            )
        else:
            pairs = (
                (f"They decided to {word} before dinner.", f"他们决定在晚饭前{meaning}。"),
                (f"Because time was limited, the team had to {word} before the meeting ended.", f"因为时间有限，团队必须在会议结束前{meaning}。"),
                (f"The coach asked the players to {word} carefully so that they could avoid another mistake.", f"教练要求队员们认真{meaning}，以免再次犯错。"),
                (f"Although the plan seemed difficult at first, the group chose to {word} after considering the possible results.", f"虽然计划一开始看起来很难，但小组考虑可能的结果后还是选择了{meaning}。"),
            )
    elif kind == "adjective":
        if lower == "able":
            pairs = (
                ("She is able to solve the problem by herself.", "她能够独自解决这个问题。"),
                ("Because he was able to stay calm, he made a better decision.", "因为他能够保持冷静，所以作出了更好的决定。"),
                ("The students were able to explain why the experiment had produced a different result.", "学生们能够解释为什么实验产生了不同的结果。"),
                ("Once the team was able to identify the real cause, it developed a practical solution for the problem.", "团队找到真正原因后，就为这个问题提出了实际的解决方案。"),
            )
        else:
            pairs = (
                (f"The room looks {word} today.", f"今天这个房间看起来很{meaning}。"),
                (f"She felt {word} when she heard the good news.", f"听到好消息时，她感到很{meaning}。"),
                (f"The {word} atmosphere helped everyone focus on the task.", f"{meaning}的氛围帮助大家专心完成任务。"),
                (f"Even though the weather was {word}, the students continued their outdoor activity as planned.", f"即使天气很{meaning}，学生们仍按计划继续户外活动。"),
            )
    elif kind == "adverb":
        pairs = (
            (f"She answered the question {word}.", f"她{meaning}地回答了问题。"),
            (f"He {word} checked the door before leaving the house.", f"他离开家前{meaning}地检查了门。"),
            (f"The speaker explained the difficult idea {word}, so most students could follow the lesson.", f"演讲者{meaning}地解释了这个难懂的想法，因此大多数学生都能跟上课程。"),
            (f"Although the problem looked confusing at first, the group {word} found a practical solution after discussing the evidence.", f"虽然问题一开始看起来很令人困惑，但小组讨论证据后{meaning}地找到了实际解决方案。"),
        )
    elif kind == "function":
        pairs = (
            (f"The word \"{word}\" appears in this short sentence.", f"“{word}”出现在这个短句中。"),
            (f"I underlined \"{word}\" in my notebook after class.", f"下课后，我在笔记本上给“{word}”画了下划线。"),
            (f"When we read the paragraph again, \"{word}\" helped us understand the relationship between the ideas.", f"我们再次阅读段落时，“{word}”帮助我们理解了各个观点之间的关系。"),
            (f"Although \"{word}\" is a small word, it can change the meaning or structure of a sentence in an important way.", f"虽然“{word}”是个小词，但它可能以重要方式改变句子的含义或结构。"),
        )
    else:
        pairs = (
            (f"The teacher talked about {word} in class.", f"老师今天在课堂上讲到了“{meaning}”。"),
            (f"We learned more about {word} during today's lesson.", f"今天的课程中，我们进一步了解了“{meaning}”。"),
            (f"The short article explains why {word} matters in everyday life.", f"这篇短文解释了为什么“{meaning}”在日常生活中很重要。"),
            (f"After reading the story, we discussed how {word} can influence people's choices in different situations.", f"读完故事后，我们讨论了“{meaning}”如何在不同情况下影响人们的选择。"),
        )

    return [(level, english, chinese) for level, (english, chinese) in zip(LEVELS, pairs)]


def ensure_schema(connection: sqlite3.Connection) -> None:
    columns = {
        row[1]
        for row in connection.execute("PRAGMA table_info(word_examples)")
    }
    if "difficulty_level" not in columns:
        connection.execute(
            "ALTER TABLE word_examples "
            "ADD COLUMN difficulty_level INTEGER NOT NULL DEFAULT 0"
        )
    connection.execute(
        "CREATE INDEX IF NOT EXISTS idx_word_examples_word_level "
        "ON word_examples(word_text, difficulty_level)"
    )


def chunks(items: list[str], size: int) -> Iterable[list[str]]:
    for start in range(0, len(items), size):
        yield items[start : start + size]


def load_words(connection: sqlite3.Connection) -> list[tuple[str, str]]:
    return connection.execute(
        """
        SELECT lower(trim(word)) AS word, translation
        FROM words
        WHERE word_list_id = ?
        GROUP BY lower(trim(word))
        ORDER BY min(id)
        """,
        (WORD_LIST_ID,),
    ).fetchall()


def generate_for_database(path: Path) -> tuple[int, int]:
    connection = sqlite3.connect(path)
    connection.execute("PRAGMA journal_mode=WAL")
    ensure_schema(connection)
    words = load_words(connection)
    word_keys = [word for word, _ in words]

    for group in chunks(word_keys, 400):
        placeholders = ",".join("?" for _ in group)
        connection.execute(
            f"DELETE FROM word_examples "
            f"WHERE source = ? AND lower(trim(word_text)) IN ({placeholders})",
            [SOURCE, *group],
        )

    rows: list[tuple[str, str, str, int, int, str]] = []
    seen: set[tuple[str, int]] = set()
    for word, translation in words:
        for level, sentence_en, sentence_cn in generated_examples(word, translation):
            sentence_en = re.sub(r"\s+", " ", sentence_en).strip()
            sentence_cn = re.sub(r"\s+", " ", sentence_cn).strip()
            key = (word, level)
            if not sentence_en or not sentence_cn or key in seen:
                raise ValueError(f"Invalid generated example: {word} level {level}")
            if word.lower() not in sentence_en.lower():
                raise ValueError(f"Target word missing: {word} -> {sentence_en}")
            seen.add(key)
            rows.append((word, sentence_en, sentence_cn, 0, level, SOURCE))

    connection.executemany(
        """
        INSERT INTO word_examples
            (word_text, sentence_en, sentence_cn, heat, difficulty_level, source)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        rows,
    )
    connection.commit()

    actual = connection.execute(
        "SELECT count(*) FROM word_examples "
        "WHERE source = ? AND difficulty_level BETWEEN 1 AND 4 "
        "AND lower(trim(word_text)) IN "
        "(SELECT lower(trim(word)) FROM words WHERE word_list_id = ?)",
        (SOURCE, WORD_LIST_ID),
    ).fetchone()[0]
    distinct_words = connection.execute(
        "SELECT count(DISTINCT lower(trim(word_text))) FROM word_examples "
        "WHERE source = ? AND difficulty_level BETWEEN 1 AND 4 "
        "AND lower(trim(word_text)) IN "
        "(SELECT lower(trim(word)) FROM words WHERE word_list_id = ?)",
        (SOURCE, WORD_LIST_ID),
    ).fetchone()[0]

    connection.execute("PRAGMA wal_checkpoint(TRUNCATE)")
    connection.close()
    return actual, distinct_words


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("databases", nargs="*", type=Path)
    args = parser.parse_args()
    databases = args.databases or list(DEFAULT_DATABASES)

    for database in databases:
        if not database.exists():
            raise FileNotFoundError(database)
        count, words = generate_for_database(database)
        print(f"{database}: {count} rows for {words} words")

    sample_db = sqlite3.connect(databases[-1])
    sample = sample_db.execute(
        """
        SELECT word_text, difficulty_level, sentence_en, sentence_cn
        FROM word_examples
        WHERE source = ?
        ORDER BY word_text, difficulty_level
        LIMIT 8
        """,
        (SOURCE,),
    ).fetchall()
    for row in sample:
        print(" | ".join(str(value) for value in row))
    sample_db.close()


if __name__ == "__main__":
    main()
