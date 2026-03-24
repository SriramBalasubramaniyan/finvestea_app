$libPath = 'c:\Users\chait\OneDrive\Desktop\GithubRepo\finvestea\finvestea\finvestea_app\lib'
$files = Get-ChildItem -Path $libPath -Recurse -Filter '*.dart'
$count = 0
foreach ($file in $files) {
    $content = Get-Content -Path $file.FullName -Raw
    if ($content -match '\.withOpacity\(') {
        $newContent = $content -replace '\.withOpacity\(', '.withValues(alpha: '
        Set-Content -Path $file.FullName -Value $newContent -NoNewline
        Write-Host "Fixed: $($file.Name)"
        $count++
    }
}
Write-Host "Total files fixed: $count"
