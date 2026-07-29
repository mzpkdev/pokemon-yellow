# Style guide

This guide describes the conventions for new and modified code. Some inherited
code predates these rules; do not reformat unrelated code solely to make it
match. When a local convention is clearer or required by a data format, follow
the surrounding code.

## Assembly

### Whitespace

- Indent instructions, data directives, macros, and nested comments with one
  tab.
- Use spaces after indentation when columns in a related table need alignment.
- Do not leave trailing whitespace.
- End every text file with a newline.
- Keep lines near 80 characters where practical. Long macro calls and data rows
  may exceed that limit when splitting them would reduce readability.
- Separate logical blocks with a blank line. Avoid comment-only blank lines.

```asm
FunctionName:
	ld a, [wExampleValue]
	and %00001111
	ret

DataTable:
	db FIRST_VALUE,  10
	db SECOND_VALUE, 20
```

### Names

- Use `PascalCase` for ROM routines and global data labels.
- Use `.snake_case` for local control-flow labels.
- Use `UPPER_CASE` for constants.
- Prefix labels for address-space-specific data:
  - `w` for WRAM
  - `s` for SRAM
  - `v` for VRAM
  - `h` for HRAM
- Prefer names that describe purpose rather than implementation or address.
- Preserve established public labels when renaming them would create noisy
  changes or break external tooling.

```asm
UpdateCompanionMood:
	ld a, [wPikachuMood]
	and a
	jr z, .neutral
	ret

.neutral
	xor a
	ret
```

### Casing

- Write CPU instructions and ordinary data macros in lowercase.
- Write structural RGBDS directives such as `SECTION`, `INCLUDE`, `INCBIN`,
  `MACRO`, and `ENDM` in uppercase.
- Match the surrounding convention for project-specific macros.

### Comments

- Put one space between `;` and comment text.
- Explain intent, constraints, or non-obvious hardware behavior. Do not narrate
  instructions that are already clear.
- Put comments above the code they describe. Use inline comments mainly for
  compact data tables.
- Keep terminology and capitalization consistent within a file.
- Document assumptions about registers, clobbered values, bank state, and
  required memory state when they are not evident from the caller.

### Data and macros

- Keep related table entries aligned when that makes fields easier to compare.
- Preserve the established ordering of canonical game data unless the change
  intentionally alters that order.
- Give macro parameters a consistent meaning across all call sites.
- Prefer a small named macro over repeated byte sequences when it makes the
  encoded structure clearer.
- Do not hide control flow or important side effects behind a macro merely to
  reduce line count.

### Correctness checks

- Use RGBDS `ASSERT` or `assert_table_length` for table sizes, address limits,
  bank boundaries, and other invariants known at assembly time.
- Avoid silently truncating values. Make intentional truncation explicit.
- Treat assembler warnings as errors. If a warning is intentional, document the
  reason and suppress only that specific case instead of weakening diagnostics
  globally.
- Build both the normal and debug ROM after changing shared assembly.
- Update `roms.sha1` only when the resulting byte-level change is intentional
  and has been reviewed.

## Python tooling and ROM tests

- Keep audit and ROM-test code readable and typed where practical.
- Put reusable gameplay flows in `tools/rom_tests/scenarios`; keep assertions in
  test modules.
- Put fast tests that do not need a built ROM in `tests/unit`; put gameplay and
  visual ROM scenarios in `tests/e2e`.
- Use the shared `emulator` fixture so every test receives isolated emulator
  state and failure output.
- Tests must not depend on execution order, shared mutable state, or files
  written by another test.
- Treat ROMs, symbol files, and committed snapshots as read-only during normal
  test runs.
- Give visual assertions descriptive, unique names.

See `tools/rom_tests/README.md` for setup and parallel-test guidance.

## Scope of formatting changes

Keep formatting changes in the same area as the functional change. Large
mechanical cleanups should be submitted separately so reviewers can distinguish
behavior changes from presentation changes.

There is no required automatic formatter for RGBDS assembly. Contributors
should use this guide, existing nearby code, strict RGBDS diagnostics, and the
CI build as the source of truth.
