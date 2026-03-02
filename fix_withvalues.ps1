Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match '\.withOpacity\(') {
        $content = $content -replace '\.withOpacity\(', '.withValues(alpha: '
        Set-Content $_.FullName $content -NoNewline
        Write-Host "Fixed: $($_.FullName)"
    }
}
Write-Host "Done!"
