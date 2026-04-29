# JSS extension tests

Golden-file regression tests for the JSS extension's title-page partials.

## What this covers

Each fixture under `fixtures/` is a minimal `.qmd` that exercises one
author / affiliation scenario. The runner renders each fixture with
`jss-pdf` (which has `keep-tex: true`), then verifies that the produced
`document.tex` contains the expected `\Address{...}` (or `\author{...}`)
fragment from `expected/<fixture-name>.tex`.

This catches regressions in the partials when:

- the JSS class file changes,
- Quarto's author/affiliation normalization changes,
- the partials themselves are edited.

It does NOT cover body rendering, bibliography, or visual PDF layout —
those are eyeballed by rendering `template.qmd`.

## Running

From this directory:

```powershell
pwsh -File run-tests.ps1
```

A passing run prints `PASS` for every fixture and exits 0.
A failing run prints a unified diff per fixture and exits non-zero.

## Updating goldens

If the partials change intentionally and the new output is correct,
re-baseline with:

```powershell
pwsh -File run-tests.ps1 -UpdateGolden
```

This rewrites every `expected/*.tex` file from the current produced
output. Review the git diff before committing.

## Adding a new fixture

1. `mkdir fixtures/NN-name/` and add a `document.qmd` with the YAML
   that exercises the scenario.
2. Run with `-UpdateGolden` to write the initial expected file.
3. Inspect the new `expected/NN-name.tex` carefully. If it looks right,
   commit both fixture and expected.
