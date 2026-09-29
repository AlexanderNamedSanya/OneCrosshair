$ErrorActionPreference = 'Stop'
$sourceRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$destinationRoot = 'C:\Users\Public\Documents\Elder Scrolls Online\live\AddOns\OneCrosshair'
$files = @(
    Get-Item -LiteralPath (Join-Path $sourceRoot 'OneCrosshair.txt')
    Get-Item -LiteralPath (Join-Path $sourceRoot 'OneCrosshair.lua')
    foreach ($folder in @('Core', 'Crosshair', 'HUD', 'Effects', 'Preview', 'Settings', 'Localization', 'Assets')) {
        Get-ChildItem -LiteralPath (Join-Path $sourceRoot $folder) -Recurse -File
    }
)

foreach ($file in $files) {
    $relativePath = $file.FullName.Substring($sourceRoot.Length + 1)
    $destination = Join-Path $destinationRoot $relativePath
    New-Item -ItemType Directory -Path (Split-Path -Parent $destination) -Force | Out-Null
    Copy-Item -LiteralPath $file.FullName -Destination $destination -Force
    if ((Get-FileHash -LiteralPath $file.FullName).Hash -ne (Get-FileHash -LiteralPath $destination).Hash) {
        throw "Deployment verification failed: $relativePath"
    }
}
Write-Output "Deployed and verified $($files.Count) files: $destinationRoot"
