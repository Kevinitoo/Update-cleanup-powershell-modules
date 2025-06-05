# Ensure NuGet is available and PowerShellGet is loaded
Install-PackageProvider -Name NuGet -Force
Import-Module PowerShellGet -Force

# Initialize tracking
$totalChecked = 0
$totalUpdated = 0
$updatedModules = @()
$removedVersions = @()
$errors = @()

# Get all installed modules (no scope filter here)
$installedModules = Get-InstalledModule -ErrorAction SilentlyContinue

foreach ($module in $installedModules) {
    $totalChecked++

    try {
        Write-Host "`nChecking module:" -ForegroundColor Cyan
        Write-Host "$($module.Name) v$($module.Version)"

        # Find latest stable version
        $latest = Find-Module -Name $module.Name -AllowPrerelease:$false -ErrorAction Stop

        if ($latest.Version -gt $module.Version) {
            Write-Host "→ Update available: v$($latest.Version)" -ForegroundColor Yellow
            Write-Host "Updating $($module.Name)..." -ForegroundColor Green

            # Update using AllUsers scope
            Update-Module -Name $module.Name -Force -Scope AllUsers
            $totalUpdated++
            $updatedModules += "$($module.Name): $($module.Version) → $($latest.Version)"

            # Remove old versions
            $versions = Get-InstalledModule -Name $module.Name -AllVersions
            foreach ($v in $versions) {
                if ($v.Version -ne $latest.Version) {
                    Write-Host "Removing old version: $($v.Version)" -ForegroundColor DarkGray
                    Uninstall-Module -Name $v.Name -RequiredVersion $v.Version -Force -ErrorAction SilentlyContinue
                    $removedVersions += "$($v.Name) v$($v.Version)"
                }
            }
        }
        else {
            Write-Host "→ Up to date." -ForegroundColor DarkGreen
        }
    }
    catch {
        $errors += "$($module.Name): $_"
        Write-Warning "Failed to process $($module.Name): $_"
    }
}

# === Final Summary ===
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
Write-Host "Modules checked: $totalChecked"
Write-Host "Modules updated: $totalUpdated"

if ($updatedModules.Count -gt 0) {
    Write-Host "`nUpdated modules:" -ForegroundColor Yellow
    $updatedModules | ForEach-Object { Write-Host "- $_" }
}

if ($removedVersions.Count -gt 0) {
    Write-Host "`nRemoved old versions:" -ForegroundColor Gray
    $removedVersions | ForEach-Object { Write-Host "- $_" }
}

if ($errors.Count -gt 0) {
    Write-Host "`nModules with errors:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "- $_" }
}
