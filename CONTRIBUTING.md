# Contributing

Thank you for contributing to Pokémon Yellow.

## Before opening a pull request

- Follow [CODING_STYLE.md](CODING_STYLE.md).
- Run the relevant checks locally with `python tools/run_ci.py`.
- Keep each pull request focused on one change.

## Pull requests

Complete every applicable section of the pull request template. Explain the
premise of the change, how it works, and include screenshots for visual
changes. Write `Not applicable` in the screenshots section when appropriate.

If you cannot run the build or tests locally, feel free to open the pull
request as a draft and use the CI results for feedback. Address any failures
before marking the pull request as ready for review.

Pull request titles must follow [Conventional Commits](https://www.conventionalcommits.org/):

```text
<type>[optional scope][!]: <description>
```

Accepted types are `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`,
`refactor`, `revert`, `style`, and `test`.

Examples:

```text
feat(battle): add a critical-hit test
fix: preserve palette order for player graphics
refactor(engine)!: change the map loading interface
```
