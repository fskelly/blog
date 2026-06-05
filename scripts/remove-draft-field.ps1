$files = Get-ChildItem posts/cloud/ -Recurse -Filter "*.md"
$updated = 0

foreach ($file in $files) {
    try {
        $content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
        
        # Remove draft line (handles various spacing)
        $newContent = $content -replace "draft:\s*(true|false)\s*`n", ""
        
        if ($content -ne $newContent) {
            Set-Content -Path $file.FullName -Value $newContent -Encoding UTF8
            $updated++
            Write-Host "Updated: $($file.Name)"
        }
    } catch {
        Write-Host "Error on $($file.Name): $_"
    }
}

Write-Host "Total updated: $updated files"
