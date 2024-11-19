#!/usr/bin/env -S pwsh -NoProfile

param(
    # Theme mode to apply
    [Parameter(Mandatory = $false, Position = 0)]
    [string]
    [ValidateSet('Light','Dark')]
    $Mode,

    # Config file path
    [Parameter(Mandatory = $false, Position = 1)]
    [string]
    $ConfigPath
)

New-Variable -Name 'DefaultConfigPaths' `
             -Option 'Constant' `
             -Value @(
                "$PSScriptRoot/config.json",
                "$HOME/.config/Set-HyprlandTheme/config.json",
                "$HOME/.config/hypr/Set-HyprlandTheme/config.json",
                "$HOME/.config/hypr/Set-HyprlandTheme.json"
             )
[psobject]$Config

# Check for config file
if (!$ConfigPath) {
    # Check default locations for config file
    foreach ($path in $DefaultConfigPaths) {
        if (Test-Path $path) {
            Write-Debug "Found config file: '$path'"
            $ConfigPath = $path
        }
    }
}
else {
    if (!$(Test-Path $ConfigPath)) {
        throw "Config not found: '${Config}'"
    }
    elseif (!$([System.IO.Path]::GetExtension()) -ne '.json') {
        throw "Config not a json file"
    }
}

# Load config
try {
    $Config = Get-Content $ConfigPath | ConvertFrom-Json
}
catch {
    throw 'Cannot load config JSON.'
}

### Settings


# TODO Toggle if not provided
if (!$Mode) {

}

### Process

# Edit Waybar
"@import '$($Waybar["$Mode"])';" | Out-File $Waybar['Config'] -Force
# Edit GTK
"@import '$($GtkCss.$Mode)';" | Out-File $GtkCss['Config'] -Force
Copy-Item -Path $GtkIni["$Mode"] -Destination $GtkIni['Config'] -Force
# Refresh GTK
gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'
# Edit QT/KDE
& plasma-apply-colorscheme $Qt["$Mode"]
# Edit Kitty
Copy-Item -Path $Kitty["$Mode"] -Destination $Kitty["Config"] -Force
# Edit Pwsh
$Pwsh["$Mode"] | Out-File -FilePath $Pwsh["Config"] -Force
# Edit superProductivity
Copy-Item -Path $SuperProductivity["$Mode"] -Destination $SuperProductivity["Config"] -Force
# Edit & restart dunst
Copy-Item -Path $Dunst["$Mode"] -Destination $Dunst["Config"]
killall dunst
systemctl start dunst --user
# Edit rofi
Copy-Item -Path $Rofi["$Mode"] -Destination $Rofi["Config"]
# Edit Cursor
gsettings set org.gnome.desktop.interface cursor-theme $Cursor["$Mode"]
hyprctl setcursor $Cursor["$Mode"] 24
# Edit TaskWarrior
$TaskwarriorContent = Get-Content $Taskwarrior["Config"]
$TaskwarriorContent = $TaskwarriorContent -replace $Taskwarrior["Pattern"],$TaskWarrior["$Mode"]
$TaskwarriorContent | Set-Content $Taskwarrior["Config"]

# Edit Hyprland
$Hyprland["$Mode"] | Out-File -FilePath $Hyprland["Config"] -Force
& hyprctl reload
