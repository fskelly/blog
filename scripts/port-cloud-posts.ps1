# =====================================================================
# scripts/port-cloud-posts.ps1
#
# One-shot porter for Hugo posts from github.com/fskelly/cloud.fskelly.com
# into this Astro+Tina blog.
#
# Source layout (after `git clone` into tmp/cloud-source):
#   tmp/cloud-source/content/posts/<YEAR>/<slug>.md           (loose)
#   tmp/cloud-source/content/posts/<YEAR>/<slug>/index.md     (page bundle)
#   tmp/cloud-source/content/posts/<YEAR>/<slug>/*.png|jpg... (bundled images)
#
# Output layout:
#   posts/cloud/<YEAR>/<slug>.md                              (Astro post)
#   public/assets/cloud/<YEAR>/<slug>/<filename>              (downloaded /
#                                                              copied images)
#
# Image strategy:
#   - Convert {{< figure src=... alt=... [caption=...] >}} to markdown.
#   - Detect image URLs pointing at github.com/fskelly/* or
#     raw.githubusercontent.com/fskelly/* and download them locally,
#     then rewrite the URL to /blog/assets/cloud/<YEAR>/<slug>/<filename>.
#   - Copy sibling images out of Hugo page bundles into the same location.
#
# Drafts:
#   All ported posts are written with `draft: true` so the user can review
#   before publishing.  Lists, the RSS feed, and per-post routes filter
#   them out (see src/pages/posts.astro etc.).
# =====================================================================

$ErrorActionPreference = 'Stop'

# --- Paths ----------------------------------------------------------------
$ScriptRoot       = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot         = Split-Path -Parent $ScriptRoot
Set-Location $RepoRoot

$SourceRoot       = Join-Path $RepoRoot 'tmp\cloud-source\content\posts'
$DestPostsRoot    = Join-Path $RepoRoot 'posts\cloud'
$DestAssetsRoot   = Join-Path $RepoRoot 'public\assets\cloud'
$ImageWebBase     = '/blog/assets/cloud'

if (-not (Test-Path $SourceRoot)) {
    throw "Source not found: $SourceRoot. Run: git clone https://github.com/fskelly/cloud.fskelly.com.git tmp/cloud-source"
}

New-Item -ItemType Directory -Path $DestPostsRoot  -Force | Out-Null
New-Item -ItemType Directory -Path $DestAssetsRoot -Force | Out-Null

# --- Helpers --------------------------------------------------------------

$ImageExtensions = @('.png','.jpg','.jpeg','.gif','.webp','.svg','.bmp')

function Convert-ToSlug([string]$Text) {
    if ([string]::IsNullOrWhiteSpace($Text)) { return '' }
    $s = $Text.ToLowerInvariant()
    $s = $s -replace '[^a-z0-9]+', '-'
    $s = $s.Trim('-')
    if ([string]::IsNullOrWhiteSpace($s)) { return 'untitled' }
    return $s
}

function Strip-Quotes([string]$value) {
    if ($null -eq $value) { return '' }
    $v = $value.Trim()
    if ($v.Length -ge 2) {
        $first = $v[0]; $last = $v[$v.Length - 1]
        if (($first -eq '"' -and $last -eq '"') -or ($first -eq "'" -and $last -eq "'")) {
            return $v.Substring(1, $v.Length - 2)
        }
    }
    return $v
}

function Parse-InlineArray([string]$value) {
    # Handles `[a, "b", 'c']` style arrays (TOML or YAML inline)
    $v = $value.Trim()
    if ($v.StartsWith('[') -and $v.EndsWith(']')) { $v = $v.Substring(1, $v.Length - 2) }
    if ([string]::IsNullOrWhiteSpace($v)) { return @() }
    return ($v -split ',' | ForEach-Object { Strip-Quotes ($_.Trim()) } | Where-Object { $_ })
}

function Parse-Frontmatter([string]$Raw) {
    # Returns @{ Body = '...'; Data = @{ key = value } } where value may be
    # a string, bool, or string[].  Supports both TOML (+++) and YAML (---).
    $result = @{ Body = $Raw; Data = @{} }

    $tomlMatch = [regex]::Match($Raw, '(?s)^\+\+\+\s*\r?\n(.*?)\r?\n\+\+\+\s*\r?\n?')
    $yamlMatch = [regex]::Match($Raw, '(?s)^---\s*\r?\n(.*?)\r?\n---\s*\r?\n?')

    if ($tomlMatch.Success) {
        $fmText = $tomlMatch.Groups[1].Value
        $result.Body = $Raw.Substring($tomlMatch.Length)
        foreach ($line in ($fmText -split "`r?`n")) {
            $m = [regex]::Match($line, '^\s*([A-Za-z0-9_]+)\s*=\s*(.+?)\s*$')
            if (-not $m.Success) { continue }
            $key = $m.Groups[1].Value
            $raw = $m.Groups[2].Value.Trim()
            if ($raw -match '^\[.*\]$') {
                $result.Data[$key] = Parse-InlineArray $raw
            } elseif ($raw -match '^(true|false)$') {
                $result.Data[$key] = [bool]::Parse($raw)
            } else {
                $result.Data[$key] = Strip-Quotes $raw
            }
        }
        return $result
    }

    if ($yamlMatch.Success) {
        $fmText = $yamlMatch.Groups[1].Value
        $result.Body = $Raw.Substring($yamlMatch.Length)
        $lines = $fmText -split "`r?`n"
        $i = 0
        while ($i -lt $lines.Length) {
            $line = $lines[$i]
            $m = [regex]::Match($line, '^([A-Za-z0-9_]+)\s*:\s*(.*)$')
            if (-not $m.Success) { $i++; continue }
            $key = $m.Groups[1].Value
            $raw = $m.Groups[2].Value.Trim()
            if ($raw -eq '') {
                # Look ahead for block list (`  - item`)
                $items = @()
                $j = $i + 1
                while ($j -lt $lines.Length -and ($lines[$j] -match '^\s*-\s*(.+)\s*$')) {
                    $items += Strip-Quotes ($matches[1].Trim())
                    $j++
                }
                if ($items.Count -gt 0) {
                    $result.Data[$key] = $items
                    $i = $j
                    continue
                }
                $result.Data[$key] = ''
            }
            elseif ($raw -match '^\[.*\]$') { $result.Data[$key] = Parse-InlineArray $raw }
            elseif ($raw -match '^(true|false)$') { $result.Data[$key] = [bool]::Parse($raw) }
            else { $result.Data[$key] = Strip-Quotes $raw }
            $i++
        }
        return $result
    }

    return $result
}

function Get-FrontmatterField {
    param([hashtable]$Data, [string[]]$Names)
    foreach ($n in $Names) {
        if ($Data.ContainsKey($n)) { return $Data[$n] }
    }
    return $null
}

function Save-RemoteImage {
    param([string]$Url, [string]$DestPath)
    try {
        $dir = Split-Path -Parent $DestPath
        if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
        if (Test-Path $DestPath) { return $true }
        Invoke-WebRequest -Uri $Url -OutFile $DestPath -UseBasicParsing -TimeoutSec 30 -ErrorAction Stop | Out-Null
        return $true
    } catch {
        Write-Warning "  ! download failed: $Url -- $($_.Exception.Message)"
        return $false
    }
}

function Convert-BlobToRaw([string]$Url) {
    # https://github.com/<owner>/<repo>/blob/<branch>/<path>?raw=true
    #   -> https://raw.githubusercontent.com/<owner>/<repo>/<branch>/<path>
    $m = [regex]::Match($Url, '^https?://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+?)(\?raw=true)?$')
    if ($m.Success) {
        return "https://raw.githubusercontent.com/$($m.Groups[1].Value)/$($m.Groups[2].Value)/$($m.Groups[3].Value)/$($m.Groups[4].Value)"
    }
    return $Url
}

function Test-FskellyImageUrl([string]$Url) {
    return ($Url -match '^https?://(raw\.githubusercontent\.com|github\.com)/fskelly/')
}

function Get-FilenameFromUrl([string]$Url) {
    $u = $Url -replace '\?.*$',''
    return ($u -split '/')[-1]
}

function Rewrite-ImageUrl {
    param(
        [string]$Url,
        [string]$Year,
        [string]$Slug,
        [ref]$FailedRef
    )
    if (-not (Test-FskellyImageUrl $Url)) { return $Url }
    $rawUrl  = Convert-BlobToRaw $Url
    $name    = Get-FilenameFromUrl $rawUrl
    if ([string]::IsNullOrWhiteSpace($name)) { return $Url }
    $destAbs = Join-Path $DestAssetsRoot (Join-Path $Year (Join-Path $Slug $name))
    if (Save-RemoteImage -Url $rawUrl -DestPath $destAbs) {
        return "$ImageWebBase/$Year/$Slug/$name"
    }
    $FailedRef.Value += "$Year/$Slug -> $rawUrl"
    return $Url
}

function Convert-Body {
    param(
        [string]$Body,
        [string]$Year,
        [string]$Slug,
        [string]$BundleDir,
        [ref]$FailedRef
    )

    # 1. Drop HTML-comment-wrapped shortcodes some posts use
    $Body = [regex]::Replace($Body, '(?ms)^\s*<!--\s*\{\{<.*?>\}\}\s*-->\s*\r?\n?', '')

    # 2. Copy local bundle images (if any) up-front so bare-filename refs work
    $localImageMap = @{}
    if ($BundleDir -and (Test-Path $BundleDir)) {
        Get-ChildItem $BundleDir -File | Where-Object { $ImageExtensions -contains $_.Extension.ToLowerInvariant() } | ForEach-Object {
            $destAbs = Join-Path $DestAssetsRoot (Join-Path $Year (Join-Path $Slug $_.Name))
            $destDir = Split-Path -Parent $destAbs
            if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir -Force | Out-Null }
            Copy-Item -Path $_.FullName -Destination $destAbs -Force
            $localImageMap[$_.Name] = "$ImageWebBase/$Year/$Slug/$($_.Name)"
        }
    }

    # 3. Convert {{< figure ... >}} to markdown images (with optional caption line).
    $Body = [regex]::Replace($Body, '\{\{<\s*figure\s+([^>]+?)\s*>\}\}', {
        param($m)
        $attrs   = $m.Groups[1].Value
        $src     = ''
        $alt     = ''
        $caption = ''
        $sMatch  = [regex]::Match($attrs, 'src\s*=\s*"([^"]*)"')
        $aMatch  = [regex]::Match($attrs, 'alt\s*=\s*"([^"]*)"')
        $tMatch  = [regex]::Match($attrs, 'title\s*=\s*"([^"]*)"')
        $cMatch  = [regex]::Match($attrs, 'caption\s*=\s*"([^"]*)"')
        if ($sMatch.Success) { $src     = $sMatch.Groups[1].Value }
        if ($aMatch.Success) { $alt     = $aMatch.Groups[1].Value } elseif ($tMatch.Success) { $alt = $tMatch.Groups[1].Value }
        if ($cMatch.Success) { $caption = $cMatch.Groups[1].Value }
        if ([string]::IsNullOrWhiteSpace($src))  { return '' }
        if ([string]::IsNullOrWhiteSpace($alt))  { $alt = 'Image' }
        $line = "![$alt]($src)"
        if (-not [string]::IsNullOrWhiteSpace($caption)) { $line += "`r`n*${caption}*" }
        return $line
    })

    # 4. Rewrite every markdown image URL.
    $Body = [regex]::Replace($Body, '!\[([^\]]*)\]\(([^)\s]+)(?:\s+"([^"]*)")?\)', {
        param($m)
        $alt    = $m.Groups[1].Value
        $url    = $m.Groups[2].Value
        $title  = $m.Groups[3].Value
        $newUrl = $url

        if ($url -match '^https?://') {
            $newUrl = Rewrite-ImageUrl -Url $url -Year $Year -Slug $Slug -FailedRef $FailedRef
        }
        elseif ($localImageMap.ContainsKey($url)) {
            $newUrl = $localImageMap[$url]
        }
        elseif ($url -notmatch '^/' -and $localImageMap.ContainsKey((Split-Path -Leaf $url))) {
            $newUrl = $localImageMap[(Split-Path -Leaf $url)]
        }

        if ([string]::IsNullOrWhiteSpace($title)) { return "![$alt]($newUrl)" }
        return "![$alt]($newUrl ""$title"")"
    })

    # 5. Tidy excessive blank lines
    $Body = [regex]::Replace($Body, '(\r?\n){3,}', "`r`n`r`n")
    return $Body.Trim() + "`r`n"
}

# --- Main loop ------------------------------------------------------------

$imported     = @()
$skipped      = @()
$failedImages = @()

$years = Get-ChildItem $SourceRoot -Directory | Where-Object { $_.Name -match '^\d{4}$' } | Sort-Object Name

foreach ($yearDir in $years) {
    $year = $yearDir.Name
    Write-Host "==> Year $year" -ForegroundColor Cyan
    $seenSlugs = @{}

    # First pass: page bundles
    $bundles = Get-ChildItem $yearDir.FullName -Directory
    foreach ($bundle in $bundles) {
        $indexPath = Join-Path $bundle.FullName 'index.md'
        if (-not (Test-Path $indexPath)) { continue }
        $folderSlug = Convert-ToSlug $bundle.Name

        try {
            $raw  = Get-Content $indexPath -Raw -Encoding UTF8
            $fm   = Parse-Frontmatter $raw
            $data = $fm.Data
            $body = $fm.Body

            $title = Get-FrontmatterField $data @('title','Title')
            if ([string]::IsNullOrWhiteSpace($title)) { $title = $bundle.Name }

            $slug = Get-FrontmatterField $data @('slug','Slug')
            if ([string]::IsNullOrWhiteSpace($slug)) { $slug = $folderSlug } else { $slug = Convert-ToSlug $slug }

            if ($seenSlugs.ContainsKey($slug)) { $skipped += "DUP bundle $year/$slug"; continue }

            $added = Get-FrontmatterField $data @('date','Date')
            if ([string]::IsNullOrWhiteSpace($added)) { $added = "$year-01-01T00:00:00Z" }

            $description = Get-FrontmatterField $data @('description','Description')
            if ([string]::IsNullOrWhiteSpace($description)) {
                $plain = ($body -replace '\{\{<[^}]+>\}\}', ' ' -replace '!\[[^\]]*\]\([^)]+\)', ' ' -replace '\[([^\]]+)\]\([^)]+\)', '$1' -replace '[#*_>`-]', ' ' -replace '\s+', ' ').Trim()
                if ($plain.Length -gt 140) { $plain = $plain.Substring(0, 140).Trim() + '...' }
                if ([string]::IsNullOrWhiteSpace($plain)) { $plain = "Post about $title" }
                $description = $plain
            }

            $tags = @()
            $rawTags = Get-FrontmatterField $data @('tags','Tags')
            if ($rawTags -is [array]) { $tags = $rawTags | ForEach-Object { Convert-ToSlug $_ } | Where-Object { $_ } }
            if ($tags.Count -eq 0) { $tags = @('azure') }
            $tags = @($tags | Select-Object -Unique)

            $cats = @()
            $rawCats = Get-FrontmatterField $data @('categories','Categories')
            if ($rawCats -is [array]) { $cats = $rawCats | ForEach-Object { Convert-ToSlug $_ } | Where-Object { $_ } }
            $cats = @($cats | Select-Object -Unique)

            $convertedBody = Convert-Body -Body $body -Year $year -Slug $slug -BundleDir $bundle.FullName -FailedRef ([ref]$failedImages)

            $outDir  = Join-Path $DestPostsRoot $year
            if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
            $outFile = Join-Path $outDir "$slug.md"

            $yaml = @()
            $yaml += '---'
            $yaml += "title: ""$($title -replace '"', '\"')"""
            $yaml += "slug: $slug"
            $yaml += 'description: >-'
            $yaml += "  $description"
            $yaml += "added: $added"
            $yaml += 'tags:'
            foreach ($t in $tags) { $yaml += "  - $t" }
            if ($cats.Count -gt 0) {
                $yaml += 'categories:'
                foreach ($c in $cats) { $yaml += "  - $c" }
            }
            $yaml += 'draft: true'
            $yaml += '---'
            $yaml += ''

            $content = ($yaml -join "`r`n") + $convertedBody
            Set-Content -Path $outFile -Value $content -Encoding UTF8
            $seenSlugs[$slug] = $true
            $imported += $outFile
            Write-Host "    + $year/$slug"
        }
        catch {
            $skipped += "FAIL bundle $indexPath : $($_.Exception.Message)"
        }
    }

    # Second pass: loose .md files
    $loose = Get-ChildItem $yearDir.FullName -File -Filter '*.md'
    foreach ($file in $loose) {
        $folderSlug = Convert-ToSlug $file.BaseName

        try {
            $raw  = Get-Content $file.FullName -Raw -Encoding UTF8
            $fm   = Parse-Frontmatter $raw
            $data = $fm.Data
            $body = $fm.Body

            $title = Get-FrontmatterField $data @('title','Title')
            if ([string]::IsNullOrWhiteSpace($title)) { $title = $file.BaseName }

            $slug = Get-FrontmatterField $data @('slug','Slug')
            if ([string]::IsNullOrWhiteSpace($slug)) { $slug = $folderSlug } else { $slug = Convert-ToSlug $slug }

            if ($seenSlugs.ContainsKey($slug)) { $skipped += "DUP loose $year/$slug (bundle wins)"; continue }

            $added = Get-FrontmatterField $data @('date','Date')
            if ([string]::IsNullOrWhiteSpace($added)) { $added = "$year-01-01T00:00:00Z" }

            $description = Get-FrontmatterField $data @('description','Description')
            if ([string]::IsNullOrWhiteSpace($description)) {
                $plain = ($body -replace '\{\{<[^}]+>\}\}', ' ' -replace '!\[[^\]]*\]\([^)]+\)', ' ' -replace '\[([^\]]+)\]\([^)]+\)', '$1' -replace '[#*_>`-]', ' ' -replace '\s+', ' ').Trim()
                if ($plain.Length -gt 140) { $plain = $plain.Substring(0, 140).Trim() + '...' }
                if ([string]::IsNullOrWhiteSpace($plain)) { $plain = "Post about $title" }
                $description = $plain
            }

            $tags = @()
            $rawTags = Get-FrontmatterField $data @('tags','Tags')
            if ($rawTags -is [array]) { $tags = $rawTags | ForEach-Object { Convert-ToSlug $_ } | Where-Object { $_ } }
            if ($tags.Count -eq 0) { $tags = @('azure') }
            $tags = @($tags | Select-Object -Unique)

            $cats = @()
            $rawCats = Get-FrontmatterField $data @('categories','Categories')
            if ($rawCats -is [array]) { $cats = $rawCats | ForEach-Object { Convert-ToSlug $_ } | Where-Object { $_ } }
            $cats = @($cats | Select-Object -Unique)

            $convertedBody = Convert-Body -Body $body -Year $year -Slug $slug -BundleDir $null -FailedRef ([ref]$failedImages)

            $outDir  = Join-Path $DestPostsRoot $year
            if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
            $outFile = Join-Path $outDir "$slug.md"

            $yaml = @()
            $yaml += '---'
            $yaml += "title: ""$($title -replace '"', '\"')"""
            $yaml += "slug: $slug"
            $yaml += 'description: >-'
            $yaml += "  $description"
            $yaml += "added: $added"
            $yaml += 'tags:'
            foreach ($t in $tags) { $yaml += "  - $t" }
            if ($cats.Count -gt 0) {
                $yaml += 'categories:'
                foreach ($c in $cats) { $yaml += "  - $c" }
            }
            $yaml += 'draft: true'
            $yaml += '---'
            $yaml += ''

            $content = ($yaml -join "`r`n") + $convertedBody
            Set-Content -Path $outFile -Value $content -Encoding UTF8
            $seenSlugs[$slug] = $true
            $imported += $outFile
            Write-Host "    + $year/$slug  (loose)"
        }
        catch {
            $skipped += "FAIL loose $($file.FullName) : $($_.Exception.Message)"
        }
    }
}

Write-Host ""
Write-Host "=================== SUMMARY ===================" -ForegroundColor Yellow
Write-Host "Imported: $($imported.Count)"
$imported | ForEach-Object { Write-Host "  $_" }
if ($skipped.Count -gt 0) {
    Write-Host ""
    Write-Host "Skipped/Failed: $($skipped.Count)" -ForegroundColor Yellow
    $skipped | ForEach-Object { Write-Host "  $_" }
}
if ($failedImages.Count -gt 0) {
    Write-Host ""
    Write-Host "Image downloads that failed: $($failedImages.Count)" -ForegroundColor Yellow
    $failedImages | ForEach-Object { Write-Host "  $_" }
}
