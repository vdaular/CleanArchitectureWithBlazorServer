ES Localization Plan

This file lists the target `.es.resx` resource files to add to the repository and provides a recommended process to populate them.

Targets list file: `docs/ES_LOCALIZATION_PLAN.txt` (contains full 66 paths)

Quick summary:
- Total target files: 66
- Culture: `es` (generic Spanish)
- Current repo state: no `*.es.resx` files exist; base/default `*.resx` files available for each component

Recommended workflow:
1. Create the `*.es.resx` files by copying the corresponding base `Component.resx` files.
2. Populate translations manually or use machine translation as initial draft (review required).
3. Run a validation script to ensure all keys exist and there are no missing placeholders.
4. Commit in a feature branch and open a PR for review.

Validation checklist:
- [ ] Key count equals base file key count
- [ ] Placeholder tokens (e.g. `{0}`, `{name}`) preserved
- [ ] No HTML or code inserted accidentally
- [ ] Files saved with UTF-8 encoding

Automation snippets

PowerShell: create copies (dry-run first)

```powershell
# Dry-run: show copy commands
Get-Content docs\ES_LOCALIZATION_PLAN.txt | ForEach-Object { "Copy `"$($_ -replace '\\','\\\\')`" from base to target" }

# Create files by copying base resx
Get-Content docs\ES_LOCALIZATION_PLAN.txt | ForEach-Object {
  $target = $_
  $base = $target -replace '\.es\.resx$','.resx'
  if (Test-Path $base -PathType Leaf) { Copy-Item -Path $base -Destination $target -WhatIf }
  else { Write-Output "Base file not found for $target" }
}
```

Machine translation note:
- If you want automatic translation, provide access to a translation service (e.g., DeepL API key). I can implement a script that:
  1. Parses base `.resx` files
  2. Sends string values to the translation API
  3. Writes translated `.es.resx` files
  4. Preserves placeholders and metadata

Next steps (choose one):
- A) Generate the 66 `.es.resx` files by copying base files (I will run the Copy without committing, in-place).
- B) Generate and populate `.es.resx` using machine translation (requires API key and confirmation).
- C) Only list and verify targets (done) — no file creation.

If you pick A or B, I will run the creation and produce a small validation report. If B, provide translation API details or confirm that using a public machine translation is acceptable.
