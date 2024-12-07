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
New-Variable -Name 'OptionalCliUtilityList' `
             -Option 'Constant' `
             -Value @(
                'gsettings',
                'plasma-apply-colorscheme'
             )
[psobject]$Config
[System.Collections.Generic.Dictionary[string,bool]]$OptionalCliUtilities = @{}

foreach ($cmd in $OptionalCliUtilityList) {
    [bool]$found = which $cmd ? $true : $false
    if ($found) {
        Write-Debug "Optional CLI Utility '$cmd' found."
    }
    else {
        Write-Warning "Optional CLI Utility '$cmd' not found, some features may not work as expected."
    }
    $OptionalCliUtilities.Add($cmd, $found)
}
$Clipse = @{
    Type = 'Replace'
    Config = "$HOME/.config/clipse/custom_theme.json"
    Light = "$HOME/.config/clipse/themes/vscode_light.json"
    Dark = "$HOME/.config/clipse/themes/vscode_dark.json"
}

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

### Process
Write-Host "Switching to ${Mode} Mode..."
foreach ($item in $Config) {
    $appName = $item.appName
    Write-Host "Switching $appName..."

    $type = $item.type
    Write-Verbose "Config Type: $type"
    
    $path = $item.path
    Write-Verbose "Config File: $path"
    
    $pathFound = Test-Path $pathFound
    if (!$pathFound) {
        Write-Warning "Config file: $path does not exist!" 
    }
    else {
        Write-Verbose 'Config file exists.'
    }
    $modeString = $item.modes.$Mode
    Write-Verbose "Config Mode String; $modeString"
    if ($item.pattern) {
        $pattern = $item.pattern
        Write-Verbose "Config Pattern: $pattern"
    }
    switch ($item.type) {
        'FileContents' {
            try { $modeString | Out-File $path }
            catch { Write-Warning "Unable to write to $path" }
        }
        'KDE' {
            if ($OptionalCliUtilities['plasma-apply-colorscheme']) {
                try { & plasma-apply-colorscheme $modeString }
                catch { Write-Warning "plasma-apply-colorscheme failed to set $modeString" }
            }
            else {
                Write-Error 'KDE: Unable to set color scheme via plasma-apply-colorscheme!'
            }
        }
        'ReplaceFile' {
            if (!$(Test-Path $modeString)) {
                Write-Warning "Config File Replacement: $modeString does not exist!"
            }
            else {
                try { Copy-Item -Path $modeString -Destination $path -Force }
                catch { Write-Warning "Failed to overwrite $path" }
            }
        }
        'Cursor' {
            if ($OptionalCliUtilities['gsettings']) {
                try {
                    gsettings set org.gnome.desktop.interface cursor-theme $modeString
                }
                catch {
                    Write-Warning "Failed to set cursor via gsettings"
                }
            }
            # Handle KDE
            try { hyprctl setcursor $modeString}
            catch { Write-Error "Failed to set cursor via hyprctl!"}
        }
        'PatternReplace' {
            # Handle file existence
            # Handle pattern validit
        }
        Default {
            Write-Warning "Unknown Config Type: $type"
        }
    }
}

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
# Edit Clipse
Copy-Item -Path $Clipse["$Mode"] -Destination $Clipse["Config"] -Force`

# Edit Hyprland
$Hyprland["$Mode"] | Out-File -FilePath $Hyprland["Config"] -Force
& hyprctl reload
