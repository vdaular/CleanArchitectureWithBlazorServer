<#
  validate-resx.ps1
  Simple, robust validator comparing base .resx files to .es.resx counterparts.
  - Finds all *.es.resx files in the repo
  - For each, finds the base .resx (replace ".es.resx" -> ".resx")
  - Compares keys (missing/extra) and placeholder token sets like {0}, {1:N}
  - Skips binary/mimetype entries and reports them separately
  - Writes a report to docs/ES_VALIDATION_REPORT_v2.txt
#>

Param()

Set-StrictMode -Version Latest

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path | Split-Path -Parent
if (-not $RepoRoot) { $RepoRoot = Get-Location }

$esFiles = Get-ChildItem -Path $RepoRoot -Recurse -Filter '*.es.resx' -ErrorAction SilentlyContinue
if (-not $esFiles) {
    Write-Host "No .es.resx files found under $RepoRoot"
    exit 1
}

$reportPath = Join-Path $RepoRoot 'docs\ES_VALIDATION_REPORT_v2.txt'
"Validation run: $(Get-Date -Format o)" | Out-File -FilePath $reportPath -Encoding utf8
"Repository: $RepoRoot`n" | Out-File -FilePath $reportPath -Encoding utf8 -Append

function Get-ResxData($path) {
    try {
        $xmlText = Get-Content -Raw -LiteralPath $path -ErrorAction Stop
        [xml]$doc = $xmlText
    } catch {
        return [pscustomobject]@{ Data = @{}; Binary = @(); Error = "Failed to parse XML: $($_.Exception.Message)" }
    }

    $dataNodes = @{}
    $binaryEntries = @()

    # Safely select <data> nodes (may be single node or node list)
    $nodes = @()
    $selected = $doc.SelectNodes('//data')
    if ($selected) { $nodes = $selected } else { $nodes = @() }

    foreach ($node in $nodes) {
        # Name can be an attribute or element depending on parser; prefer attribute
        $name = $null
        if ($node.Attributes -and $node.Attributes['name']) { $name = $node.Attributes['name'].Value }
        elseif ($node.GetAttribute) { $name = $node.GetAttribute('name') }
        elseif ($node.name) { $name = $node.name }
        if (-not $name) { continue }

        # If the data node has a mimetype or type attribute indicating binary, record and skip
        $isBinary = $false
        if ($node.Attributes -ne $null) {
            if ($node.Attributes['mimetype'] -ne $null -or $node.Attributes['type'] -ne $null) { $isBinary = $true }
        }
        if ($isBinary) { $binaryEntries += $name; continue }

        # Extract the <value> text safely
        $valueNode = $node.SelectSingleNode('value')
        $value = ''
        if ($valueNode -ne $null) { $value = $valueNode.InnerText }

        $dataNodes[$name] = $value
    }

    return [pscustomobject]@{ Data = $dataNodes; Binary = $binaryEntries; Error = $null }
}

function Extract-Placeholders($text) {
    if (-not $text) { return @() }
    $matches = [regex]::Matches($text, '\{(\d+)(?:[^}]*)\}')
    $list = @()
    foreach ($m in $matches) { $list += $m.Groups[1].Value }
    return ($list | Sort-Object -Unique)
}

foreach ($es in $esFiles) {
    $esPath = $es.FullName
    $basePath = $esPath -replace '\.es\.resx$','.resx'

    "$esPath" | Out-File -FilePath $reportPath -Append -Encoding utf8

    if (-not (Test-Path $basePath)) {
        "  ERROR: base .resx not found: $basePath`n" | Out-File -FilePath $reportPath -Append -Encoding utf8
        continue
    }

    $base = Get-ResxData -path $basePath
    $esdata = Get-ResxData -path $esPath

    if ($base.Error) { "  ERROR: Failed to parse base: $($base.Error)" | Out-File -FilePath $reportPath -Append -Encoding utf8; continue }
    if ($esdata.Error) { "  ERROR: Failed to parse es file: $($esdata.Error)" | Out-File -FilePath $reportPath -Append -Encoding utf8; continue }

    $baseKeys = @((@($base.Data.Keys) | Sort-Object))
    $esKeys   = @((@($esdata.Data.Keys) | Sort-Object))

    $missing = @($baseKeys | Where-Object { -not ($esKeys -contains $_) })
    $extra   = @($esKeys | Where-Object { -not ($baseKeys -contains $_) })

    # Ensure binary lists are arrays
    $base.Binary = @($base.Binary)
    $esdata.Binary = @($esdata.Binary)

    $missingCount = ($missing | Measure-Object).Count
    $extraCount = ($extra | Measure-Object).Count
    $keyCount = ($baseKeys | Measure-Object).Count

    if ($missingCount -eq 0 -and $extraCount -eq 0) {
        "  Keys: OK (same count: $keyCount)" | Out-File -FilePath $reportPath -Append -Encoding utf8
    } else {
        if ($missingCount -gt 0) { "  Missing in es.resx: $($missing -join ', ')" | Out-File -FilePath $reportPath -Append -Encoding utf8 }
        if ($extraCount -gt 0) { "  Extra in es.resx: $($extra -join ', ')" | Out-File -FilePath $reportPath -Append -Encoding utf8 }
    }

    # Binary entries
    $baseBinaryCount = ($base.Binary | Measure-Object).Count
    $esBinaryCount = ($esdata.Binary | Measure-Object).Count
    if ($baseBinaryCount -gt 0 -or $esBinaryCount -gt 0) {
        "  Binary/mimetype entries (skipped): base: $($base.Binary -join ', '); es: $($esdata.Binary -join ', ')" | Out-File -FilePath $reportPath -Append -Encoding utf8
    }

    # Placeholder comparison for keys present in both
    $common = $baseKeys | Where-Object { $esKeys -contains $_ }
    foreach ($k in $common) {
        $bv = $base.Data[$k]
        $ev = $esdata.Data[$k]
        $bp = Extract-Placeholders -text $bv
        $ep = Extract-Placeholders -text $ev
        $bpStr = if ($bp) { $bp -join ',' } else { '<none>' }
        $epStr = if ($ep) { $ep -join ',' } else { '<none>' }
        if (($bpStr) -ne ($epStr)) {
            "  Placeholder mismatch for key: $k`n    base: $bpStr`n    es:   $epStr" | Out-File -FilePath $reportPath -Append -Encoding utf8
        }
    }

    "`n" | Out-File -FilePath $reportPath -Append -Encoding utf8
}

Write-Host "Wrote: $reportPath"
