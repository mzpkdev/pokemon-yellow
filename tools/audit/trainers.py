#!/usr/bin/env python3
"""Validate trainer parties and their special-move overrides.

This intentionally parses only the small, regular subset of RGBDS syntax used by
data/trainers/{parties,special_moves}.asm.  It does not need a built ROM or RGBDS.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path


DB_RE = re.compile(r"^\s*db\s+(.+?)\s*$", re.IGNORECASE)
LABEL_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s*$")
POINTER_RE = re.compile(r"^\s*dw\s+([A-Za-z_][A-Za-z0-9_]*)\s*$")


def clean(line: str) -> str:
    return line.split(";", 1)[0].strip()


def fields(line: str) -> list[str] | None:
    match = DB_RE.match(clean(line))
    if not match:
        return None
    return [part.strip() for part in match.group(1).split(",")]


def key(name: str) -> str:
    name = re.sub(r"Data$", "", name, flags=re.IGNORECASE)
    return re.sub(r"[^A-Za-z0-9]", "", name).upper()


def parse_parties(path: Path) -> tuple[list[dict], dict[str, list[dict]], list[str]]:
    lines = path.read_text(encoding="utf-8").splitlines()
    errors: list[str] = []
    pointers: list[str] = []
    in_pointers = False
    for line in lines:
        stripped = clean(line)
        if stripped == "TrainerDataPointers:":
            in_pointers = True
            continue
        if in_pointers and stripped.startswith("assert_table_length"):
            break
        if in_pointers:
            match = POINTER_RE.match(stripped)
            if match:
                pointers.append(match.group(1))

    classes: dict[str, list[dict]] = {key(label): [] for label in pointers}
    labels_by_key = {key(label): label for label in pointers}
    current: str | None = None
    for lineno, line in enumerate(lines, 1):
        stripped = clean(line)
        match = LABEL_RE.match(stripped)
        if match:
            candidate = key(match.group(1))
            current = candidate if candidate in classes else None
            continue
        values = fields(line)
        if current is None or values is None:
            continue
        if values == ["-1"]:
            current = None
            continue
        if not values or values[-1] != "0":
            errors.append(f"{path}:{lineno}: trainer party is not 0-terminated")
            continue
        body = values[:-1]
        mons: list[dict] = []
        if body and body[0].upper() == "$FF":
            pairs = body[1:]
            if len(pairs) % 2:
                errors.append(f"{path}:{lineno}: $FF party has an incomplete level/species pair")
                continue
            for pos in range(0, len(pairs), 2):
                level_text, species = pairs[pos : pos + 2]
                try:
                    level = int(level_text, 0)
                except ValueError:
                    errors.append(f"{path}:{lineno}: invalid level {level_text!r}")
                    level = -1
                mons.append({"level": level, "species": species})
        elif body:
            try:
                level = int(body[0], 0)
            except ValueError:
                errors.append(f"{path}:{lineno}: invalid shared level {body[0]!r}")
                level = -1
            mons = [{"level": level, "species": species} for species in body[1:]]
        else:
            errors.append(f"{path}:{lineno}: empty trainer party")

        if not 1 <= len(mons) <= 6:
            errors.append(f"{path}:{lineno}: party size {len(mons)} is outside 1..6")
        for mon in mons:
            if not 1 <= mon["level"] <= 100:
                errors.append(
                    f"{path}:{lineno}: {mon['species']} level {mon['level']} is outside 1..100"
                )
        classes[current].append(
            {"id": len(classes[current]) + 1, "line": lineno, "pokemon": mons}
        )

    class_manifest = [
        {"class": label, "constant_key": key(label), "party_count": len(classes[key(label)])}
        for label in pointers
    ]
    return class_manifest, classes, errors


def parse_special_moves(
    path: Path, classes: dict[str, list[dict]]
) -> tuple[list[dict], list[str]]:
    errors: list[str] = []
    records: list[dict] = []
    lines = path.read_text(encoding="utf-8").splitlines()
    active: dict | None = None
    started = False

    for lineno, line in enumerate(lines, 1):
        if clean(line) == "SpecialTrainerMoves:":
            started = True
            continue
        if not started:
            continue
        values = fields(line)
        if values is None:
            continue
        if values == ["-1"]:
            if active is not None:
                errors.append(f"{path}:{lineno}: missing record terminator before end marker")
            break
        if active is None:
            if len(values) != 2:
                errors.append(f"{path}:{lineno}: expected trainer class and party id")
                continue
            class_name, party_text = values
            try:
                party_id = int(party_text, 0)
            except ValueError:
                errors.append(f"{path}:{lineno}: invalid party id {party_text!r}")
                party_id = -1
            active = {
                "class": class_name,
                "party_id": party_id,
                "line": lineno,
                "moves": [],
            }
            continue
        if values == ["0"]:
            records.append(active)
            active = None
            continue
        if len(values) != 3:
            errors.append(f"{path}:{lineno}: expected party slot, move slot, and move")
            continue
        mon_text, slot_text, move = values
        try:
            mon_slot, move_slot = int(mon_text, 0), int(slot_text, 0)
        except ValueError:
            errors.append(f"{path}:{lineno}: invalid numeric slot")
            continue
        active["moves"].append(
            {"party_slot": mon_slot, "move_slot": move_slot, "move": move, "line": lineno}
        )

    if active is not None:
        errors.append(f"{path}:{active['line']}: unterminated special-move record")

    seen_records: set[tuple[str, int]] = set()
    for record in records:
        class_key = key(record["class"])
        record_key = (class_key, record["party_id"])
        if record_key in seen_records:
            errors.append(
                f"{path}:{record['line']}: duplicate special-move record for "
                f"{record['class']} party {record['party_id']}"
            )
        seen_records.add(record_key)
        parties = classes.get(class_key)
        if parties is None:
            errors.append(f"{path}:{record['line']}: unknown trainer class {record['class']}")
            continue
        if not 1 <= record["party_id"] <= len(parties):
            errors.append(
                f"{path}:{record['line']}: {record['class']} party {record['party_id']} "
                f"is outside 1..{len(parties)}"
            )
            continue
        party_size = len(parties[record["party_id"] - 1]["pokemon"])
        seen_slots: set[tuple[int, int]] = set()
        for move in record["moves"]:
            slot = (move["party_slot"], move["move_slot"])
            if not 1 <= move["party_slot"] <= party_size:
                errors.append(
                    f"{path}:{move['line']}: party slot {move['party_slot']} "
                    f"is outside 1..{party_size}"
                )
            if not 1 <= move["move_slot"] <= 4:
                errors.append(
                    f"{path}:{move['line']}: move slot {move['move_slot']} is outside 1..4"
                )
            if slot in seen_slots:
                errors.append(f"{path}:{move['line']}: duplicate override for slots {slot}")
            seen_slots.add(slot)
    return records, errors


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--root", type=Path, default=Path(__file__).resolve().parents[2],
        help="repository root (defaults to the script's repository)",
    )
    parser.add_argument("--manifest", type=Path, help="write parsed data as JSON")
    args = parser.parse_args()
    parties_path = args.root / "data/trainers/parties.asm"
    moves_path = args.root / "data/trainers/special_moves.asm"

    class_manifest, classes, errors = parse_parties(parties_path)
    records, move_errors = parse_special_moves(moves_path, classes)
    errors.extend(move_errors)
    manifest = {
        "summary": {
            "trainer_classes": len(class_manifest),
            "parties": sum(item["party_count"] for item in class_manifest),
            "special_move_records": len(records),
            "special_move_overrides": sum(len(item["moves"]) for item in records),
        },
        "classes": class_manifest,
        "parties": classes,
        "special_moves": records,
    }
    if args.manifest:
        args.manifest.parent.mkdir(parents=True, exist_ok=True)
        args.manifest.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    summary = manifest["summary"]
    print(
        f"Audited {summary['trainer_classes']} classes, {summary['parties']} parties, "
        f"{summary['special_move_records']} special-move records "
        f"({summary['special_move_overrides']} overrides)."
    )
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        print(f"Trainer audit failed with {len(errors)} error(s).", file=sys.stderr)
        return 1
    print("Trainer audit passed.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
