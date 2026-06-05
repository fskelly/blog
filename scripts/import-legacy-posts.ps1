$ErrorActionPreference = 'Stop'

function Convert-ToSlug([string]$Text) {
  if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
  $s = $Text.ToLowerInvariant()
  $s = $s -replace '[^a-z0-9]+', '-'
  $s = $s.Trim('-')
  if ([string]::IsNullOrWhiteSpace($s)) { return 'uncategorized' }
  return $s
}

function Strip-Quotes([string]$value) {
  if ($null -eq $value) { return '' }
  return ($value -replace '^[''\"]|[''\"]$', '')
}

function Parse-Attr([string]$attrText, [string]$name) {
  $pattern = ('\b{0}\s*=\s*"([^"]*)"' -f [regex]::Escape($name))
  $m = [regex]::Match($attrText, $pattern)
  if ($m.Success) { return $m.Groups[1].Value }
  return ''
}

function Convert-Body([string]$body) {
  $body = [regex]::Replace($body, '(?ms)^\s*<!--\s*\{\{<.*?>\}\}\s*-->\s*\r?\n?', '')

  $body = [regex]::Replace($body, '\{\{<\s*(figure|figurelink)\s+([^>]+?)\s*>\}\}', {
    param($m)
    $attrs = $m.Groups[2].Value
    $src = Parse-Attr $attrs 'src'
    $alt = Parse-Attr $attrs 'alt'
    if ([string]::IsNullOrWhiteSpace($alt)) { $alt = Parse-Attr $attrs 'title' }
    if ([string]::IsNullOrWhiteSpace($alt)) { $alt = 'Image' }
    if ([string]::IsNullOrWhiteSpace($src)) { return '' }
    return "[![$alt]($src)]($src)"
  })

  $body = [regex]::Replace($body, '\{\{<\s*video\s+"([^"]+)"\s+"([^"]+)"\s*>\}\}', '<video controls src="$1" class="$2"></video>')
  $body = [regex]::Replace($body, '(\r?\n){3,}', "`r`n`r`n")

  return $body.Trim() + "`r`n"
}

$srcRoot = Resolve-Path '..\me.fskelly.com-src\content\posts'
$dstRoot = Resolve-Path '.\posts'

$existing = @{}
Get-ChildItem $dstRoot -Recurse -File -Filter *.md | ForEach-Object {
  $text = Get-Content $_.FullName -Raw
  $m = [regex]::Match($text, '(?m)^slug:\s*(.+)$')
  if ($m.Success) { $existing[$m.Groups[1].Value.Trim()] = $true }
}

$sourceFiles = Get-ChildItem $srcRoot -Recurse -File -Filter 'index.md' |
  Where-Object { $_.FullName -match '\\content\\posts\\(20\d{2})\\[^\\]+\\index\.md$' }

$imported = @()
$skipped = @()

foreach ($file in $sourceFiles) {
  $full = $file.FullName
  $mPath = [regex]::Match($full, '\\content\\posts\\(20\d{2})\\([^\\]+)\\index\.md$')
  if (-not $mPath.Success) { continue }

  $year = [int]$mPath.Groups[1].Value
  $folderSlug = $mPath.Groups[2].Value

  if ($year -gt 2024) {
    $skipped += "SKIP year>2024: $full"
    continue
  }

  $raw = Get-Content $full -Raw
  $mFm = [regex]::Match($raw, '(?s)^\+\+\+\s*(.*?)\s*\+\+\+\s*')
  if (-not $mFm.Success) {
    $skipped += "SKIP no frontmatter: $full"
    continue
  }

  $fmText = $mFm.Groups[1].Value
  $body = $raw.Substring($mFm.Length)

  $kv = @{}
  foreach ($line in ($fmText -split "`r?`n")) {
    $mkv = [regex]::Match($line, '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$')
    if ($mkv.Success) {
      $kv[$mkv.Groups[1].Value] = $mkv.Groups[2].Value
    }
  }

  if ($kv.ContainsKey('draft') -and $kv['draft'].ToLowerInvariant() -eq 'true') {
    $skipped += "SKIP draft: $full"
    continue
  }

  $title = ''
  if ($kv.ContainsKey('title')) { $title = Strip-Quotes $kv['title'] }
  if ([string]::IsNullOrWhiteSpace($title)) { $title = $folderSlug }

  $slug = if ($kv.ContainsKey('slug')) { Convert-ToSlug (Strip-Quotes $kv['slug']) } else { Convert-ToSlug $folderSlug }
  if ([string]::IsNullOrWhiteSpace($slug)) { $slug = Convert-ToSlug $title }

  if ($existing.ContainsKey($slug)) {
    $skipped += "SKIP existing slug: $slug ($full)"
    continue
  }

  $added = if ($kv.ContainsKey('date')) { Strip-Quotes $kv['date'] } else { (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssK') }

  $description = ''
  if ($kv.ContainsKey('description')) { $description = Strip-Quotes $kv['description'] }
  if ([string]::IsNullOrWhiteSpace($description)) {
    $plain = ($body -replace '<[^>]+>', ' ' -replace '\[([^\]]+)\]\([^\)]+\)', '$1' -replace '\s+', ' ').Trim()
    if ($plain.Length -gt 140) { $plain = $plain.Substring(0, 140).Trim() + '...' }
    if ([string]::IsNullOrWhiteSpace($plain)) { $plain = "Post about $title" }
    $description = $plain
  }

  $tags = @()
  if ($kv.ContainsKey('tags')) {
    $arr = $kv['tags'].Trim().TrimStart('[').TrimEnd(']')
    if (-not [string]::IsNullOrWhiteSpace($arr)) {
      $tags = $arr.Split(',') |
        ForEach-Object { Convert-ToSlug (Strip-Quotes ($_.Trim())) } |
        Where-Object { $_ }
    }
  }
  if ($tags.Count -eq 0) { $tags = @('personal') }
  $tags = $tags | Select-Object -Unique

  $categories = @()
  if ($kv.ContainsKey('topics')) {
    $arr = $kv['topics'].Trim().TrimStart('[').TrimEnd(']')
    if (-not [string]::IsNullOrWhiteSpace($arr)) {
      $categories = $arr.Split(',') |
        ForEach-Object { Convert-ToSlug (Strip-Quotes ($_.Trim())) } |
        Where-Object { $_ }
    }
  }
  $categories = $categories | Select-Object -Unique

  $convertedBody = Convert-Body $body

  $outDir = Join-Path $dstRoot $year
  if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }
  $outFile = Join-Path $outDir "$slug.md"

  $yaml = @()
  $yaml += '---'
  $yaml += "title: $title"
  $yaml += "added: $added"
  $yaml += "slug: $slug"
  $yaml += 'description: >-'
  $yaml += "  $description"
  $yaml += 'tags:'
  foreach ($t in $tags) { $yaml += "  - $t" }
  if ($categories.Count -gt 0) {
    $yaml += 'categories:'
    foreach ($c in $categories) { $yaml += "  - $c" }
  }
  $yaml += '---'
  $yaml += ''

  $content = ($yaml -join "`r`n") + $convertedBody
  Set-Content -Path $outFile -Value $content -Encoding UTF8

  $existing[$slug] = $true
  $imported += $outFile
}

Write-Output "IMPORTED ($($imported.Count))"
$imported | ForEach-Object { Write-Output $_ }
Write-Output "SKIPPED ($($skipped.Count))"
$skipped | ForEach-Object { Write-Output $_ }
