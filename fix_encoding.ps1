Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $bytes = [System.IO.File]::ReadAllBytes($_.FullName)
    # Check for any BOM
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        Write-Host "UTF-8 BOM found: $($_.FullName) - removing BOM..."
        $content = [System.IO.File]::ReadAllText($_.FullName)
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
        Write-Host "Fixed: $($_.FullName)"
    } else {
        Write-Host "OK: $($_.Name) starts with: $($bytes[0]) $($bytes[1]) $($bytes[2])"
    }
}
Write-Host "Done!"
