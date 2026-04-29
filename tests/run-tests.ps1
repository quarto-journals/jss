<#
.SYNOPSIS
    Golden-file regression tests for the JSS extension's title-page partials.

.DESCRIPTION
    Renders every fixture under fixtures/ with `quarto render --to jss-pdf`
    and verifies that the produced document.tex contains the expected
    fragment from expected/<name>.tex.

    Fixtures 01-07 verify the \Address{...} block (output of
    partials/_print-address.tex via partials/title.tex).
    Fixture 08 verifies the \author{...} block
    (partials/_print-author.tex via partials/title.tex).

.PARAMETER UpdateGolden
    Re-baseline expected/*.tex from the current produced output.
    Use after intentionally changing the partials. Review the git
    diff before committing the new goldens.

.PARAMETER KeepArtifacts
    Skip the post-test cleanup of document.tex / document.pdf /
    document_files/ inside each fixture directory.

.EXAMPLE
    pwsh -File run-tests.ps1
    pwsh -File run-tests.ps1 -UpdateGolden
#>
[CmdletBinding()]
param(
    [switch]$UpdateGolden,
    [switch]$KeepArtifacts
)

$ErrorActionPreference = 'Stop'

$testsDir    = $PSScriptRoot
$fixturesDir = Join-Path $testsDir 'fixtures'
$expectedDir = Join-Path $testsDir 'expected'

if (-not (Test-Path $expectedDir)) {
    New-Item -ItemType Directory -Path $expectedDir | Out-Null
}

# --- Helpers -----------------------------------------------------------------

function Extract-AddressBlock {
    param([string]$Tex)
    # Match from a line that is exactly "\Address{" up to and including the
    # next line that is exactly "}". The JSS partial emits both on their own
    # lines.
    $pattern = '(?ms)^\\Address\{$.*?^\}$'
    $m = [regex]::Match($Tex, $pattern)
    if ($m.Success) { return $m.Value } else { return $null }
}

function Extract-AuthorBlock {
    param([string]$Tex)
    # \author{...} can span multiple lines and contains nested braces
    # (e.g. \orcidlink{...}). Walk the string and balance braces.
    $idx = $Tex.IndexOf('\author{')
    if ($idx -lt 0) { return $null }
    $start = $idx
    $depth = 0
    for ($i = $start + '\author'.Length; $i -lt $Tex.Length; $i++) {
        $c = $Tex[$i]
        if ($c -eq '{') { $depth++ }
        elseif ($c -eq '}') {
            $depth--
            if ($depth -eq 0) {
                return $Tex.Substring($start, $i - $start + 1)
            }
        }
    }
    return $null
}

function Get-FixtureKind {
    param([string]$Name)
    if ($Name -like '08-*') { return 'author' } else { return 'address' }
}

function Normalize-Lines {
    param([string]$Text)
    if ($null -eq $Text) { return '' }
    return ($Text -replace "`r`n", "`n").TrimEnd()
}

function Show-Diff {
    param([string]$Expected, [string]$Produced)
    Write-Host '--- expected ---' -ForegroundColor Yellow
    Write-Host $Expected
    Write-Host '--- produced ---' -ForegroundColor Yellow
    Write-Host $Produced
    Write-Host '----------------' -ForegroundColor Yellow
}

function Run-AuxiliaryAssertions {
    param(
        [string]$Name,
        [string]$Block
    )
    $errors = @()
    switch -Wildcard ($Name) {
        '02-*' {
            # Single author with TWO affiliations -> exactly one \emph{and}
            $count = ([regex]::Matches($Block, [regex]::Escape('\emph{and}'))).Count
            if ($count -ne 1) {
                $errors += "expected exactly 1 '\emph{and}', found $count"
            }
        }
        '04-*' {
            # No affiliations -> zero \emph{and}
            $count = ([regex]::Matches($Block, [regex]::Escape('\emph{and}'))).Count
            if ($count -ne 0) {
                $errors += "expected 0 '\emph{and}' for no-affiliation author, found $count"
            }
        }
        '03-*' {
            # Two authors -> two \\~ separators
            $count = ([regex]::Matches($Block, '\\\\~')).Count
            if ($count -lt 2) {
                $errors += "expected at least 2 '\\~' author separators, found $count"
            }
        }
        '06-*' {
            # state: CA -> CA must appear
            if ($Block -notmatch ', CA') {
                $errors += "expected 'CA' to render in Address (state alias regression)"
            }
        }
        '07-*' {
            # postal-code 6020 + city Innsbruck + country Austria
            if ($Block -notmatch '6020 Innsbruck, Austria') {
                $errors += "expected '6020 Innsbruck, Austria' line in Address"
            }
        }
        '08-*' {
            # \author block -> must contain \orcidlink{...}
            if ($Block -notmatch [regex]::Escape('\orcidlink{0000-0000-0000-0001}')) {
                $errors += "expected '\orcidlink{0000-0000-0000-0001}' in \\author block"
            }
        }
    }
    return $errors
}

# --- Main loop ---------------------------------------------------------------

$results = New-Object System.Collections.ArrayList

$fixtures = Get-ChildItem $fixturesDir -Directory | Sort-Object Name

foreach ($fixture in $fixtures) {
    $name         = $fixture.Name
    $qmd          = Join-Path $fixture.FullName 'document.qmd'
    $producedTex  = Join-Path $fixture.FullName 'document.tex'
    $producedPdf  = Join-Path $fixture.FullName 'document.pdf'
    $expectedFile = Join-Path $expectedDir "$name.tex"
    $kind         = Get-FixtureKind -Name $name

    Write-Host ''
    Write-Host "[$name] rendering ($kind block)..." -ForegroundColor Cyan

    Remove-Item $producedTex -ErrorAction SilentlyContinue
    Remove-Item $producedPdf -ErrorAction SilentlyContinue

    $renderLog = & quarto render $qmd --to jss-pdf 2>&1
    $renderExit = $LASTEXITCODE

    if ($renderExit -ne 0 -or -not (Test-Path $producedTex)) {
        Write-Host "  render failed (exit $renderExit)" -ForegroundColor Red
        Write-Host ($renderLog | Out-String)
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'FAIL'; Reason = "render failed (exit $renderExit)" })
        continue
    }

    $tex = Get-Content $producedTex -Raw
    $tex = $tex -replace "`r`n", "`n"

    $block = if ($kind -eq 'author') {
        Extract-AuthorBlock -Tex $tex
    } else {
        Extract-AddressBlock -Tex $tex
    }

    if (-not $block) {
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'FAIL'; Reason = "no $kind block found in produced .tex" })
        continue
    }

    $blockNormalized = Normalize-Lines $block

    if ($UpdateGolden) {
        # Write with LF line endings to keep diffs portable
        [System.IO.File]::WriteAllText($expectedFile, "$blockNormalized`n")
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'GOLDEN'; Reason = '' })
        continue
    }

    if (-not (Test-Path $expectedFile)) {
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'FAIL'; Reason = "no expected file (run with -UpdateGolden to create)" })
        continue
    }

    $expected = (Get-Content $expectedFile -Raw)
    $expectedNormalized = Normalize-Lines $expected

    $auxErrors = Run-AuxiliaryAssertions -Name $name -Block $blockNormalized

    if ($blockNormalized -ne $expectedNormalized) {
        Show-Diff -Expected $expectedNormalized -Produced $blockNormalized
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'FAIL'; Reason = 'block mismatch' })
        continue
    }

    if ($auxErrors.Count -gt 0) {
        foreach ($e in $auxErrors) { Write-Host "  $e" -ForegroundColor Red }
        [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'FAIL'; Reason = ($auxErrors -join '; ') })
        continue
    }

    [void]$results.Add([PSCustomObject]@{ Fixture = $name; Status = 'PASS'; Reason = '' })
}

# --- Cleanup -----------------------------------------------------------------

if (-not $KeepArtifacts) {
    foreach ($fixture in $fixtures) {
        # Pandoc / LaTeX build artifacts
        Remove-Item (Join-Path $fixture.FullName 'document.tex')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.pdf')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.aux')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.log')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.out')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.bbl')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document.blg')   -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'document_files') -Recurse -ErrorAction SilentlyContinue
        # format-resources Quarto stages alongside the document
        Remove-Item (Join-Path $fixture.FullName 'jss.cls')        -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'jss.bst')        -ErrorAction SilentlyContinue
        Remove-Item (Join-Path $fixture.FullName 'jsslogo.jpg')    -ErrorAction SilentlyContinue
    }
}

# --- Summary -----------------------------------------------------------------

Write-Host ''
Write-Host '=== Summary ===' -ForegroundColor Cyan
$results | Format-Table -AutoSize

$failed = ($results | Where-Object Status -eq 'FAIL').Count
$passed = ($results | Where-Object Status -eq 'PASS').Count
$golden = ($results | Where-Object Status -eq 'GOLDEN').Count

Write-Host ("PASS: {0}  FAIL: {1}  GOLDEN: {2}" -f $passed, $failed, $golden)

if ($UpdateGolden) {
    Write-Host ''
    Write-Host 'Goldens written. Review the diff before committing:' -ForegroundColor Yellow
    Write-Host '  git -C ../.. diff -- tests/expected/'
}

exit $failed
