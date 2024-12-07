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

begin {
    Add-Type -AssemblyName 'System.Collections.Generic'

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
    $OptionalCliUtilities = [Dictionary[string,bool]]::new()
    $AppsNotFound = [List[string]]::new()

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

    Write-Debug "Checking for config file..."
    if (!$ConfigPath) {
        Write-Debug "Config file path not provided. Checking default locations..."
        foreach ($path in $DefaultConfigPaths) {
            if (Test-Path $path) {
                Write-Debug "Found config file: '$path'"
                $ConfigPath = $path
            }
        }
    }
    else {
        Write-Debug "Config file path provided. Checking for existence and validity..."
        if (!$(Test-Path $ConfigPath)) {
            throw "Config not found: '${Config}'"
        }
        elseif (!$([System.IO.Path]::GetExtension($ConfigPath)) -ne 'json' -or
                !$([System.IO.Path]::GetExtension($ConfigPath)) -ne 'jsonc') {
            throw "Config file extension indicates the provided config file is not a json file."
        }
    }

    Write-Debug "Loading config file ($ConfigPath)..."
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json }
    catch { throw 'Cannot load config JSON.' }

    Write-Debug "Checking config entries..."
    foreach ($item in $Config) {
        Write-Debug "Checking config entry for '$($item.appName)'..."
        if (!$(Test-Path $item.path)) {
            Write-Warning "$($item.appName): Configuration file not found at '$($item.path)'!"
            $AppsNotFound.Add($item.appName)
        }
    }
}

process {
    Write-Host "Switching to ${Mode} Mode..."
    foreach ($item in $Config) {
        if ($AppsNotFound -contains $item.appName) { continue }
        
        switch ($item.type) {
            'FileContents' {
                try { $modeString | Out-File $item.path }
                catch { Write-Error "Unable to write to $($item.path)" }
            }
            'KDE' {
                if ($OptionalCliUtilities['plasma-apply-colorscheme']) {
                    try { & plasma-apply-colorscheme $modeString }
                    catch { Write-Error "plasma-apply-colorscheme failed to set $modeString" }
                }
                else {
                    Write-Error 'KDE: Unable to set color scheme via plasma-apply-colorscheme!'
                }
            }
            'ReplaceFile' {
                if (!$(Test-Path $modeString)) {
                    Write-Error "Config File Replacement: $modeString does not exist!"
                }
                else {
                    try { Copy-Item -Path $modeString -Destination $item.path -Force }
                    catch { Write-Error "Failed to overwrite $($item.path)" }
                }
            }
            'Cursor' {
                if ($OptionalCliUtilities['gsettings']) {
                    try {
                        iex "gsettings set org.gnome.desktop.interface cursor-theme $modeString"
                    }
                    catch {
                        Write-Error "Failed to set cursor via gsettings"
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
                Write-Error "Unknown Config Type: $($item.type)"
            }
        }
    }
}


end {}

# Old Code for reference #

# # Edit Waybar
# "@import '$($Waybar["$Mode"])';" | Out-File $Waybar['Config'] -Force

# # Edit GTK
# "@import '$($GtkCss.$Mode)';" | Out-File $GtkCss['Config'] -Force
# Copy-Item -Path $GtkIni["$Mode"] -Destination $GtkIni['Config'] -Force

# # Refresh GTK
# gsettings set org.gnome.desktop.interface gtk-theme 'Breeze-Dark'

# # Edit QT/KDE
# & plasma-apply-colorscheme $Qt["$Mode"]

# # Edit Kitty
# Copy-Item -Path $Kitty["$Mode"] -Destination $Kitty["Config"] -Force

# # Edit Pwsh
# $Pwsh["$Mode"] | Out-File -FilePath $Pwsh["Config"] -Force

# # Edit superProductivity
# Copy-Item -Path $SuperProductivity["$Mode"] -Destination $SuperProductivity["Config"] -Force

# # Edit & restart dunst
# Copy-Item -Path $Dunst["$Mode"] -Destination $Dunst["Config"]
# killall dunst
# systemctl start dunst --user

# # Edit rofi
# Copy-Item -Path $Rofi["$Mode"] -Destination $Rofi["Config"]

# # Edit Cursor
# gsettings set org.gnome.desktop.interface cursor-theme $Cursor["$Mode"]
# hyprctl setcursor $Cursor["$Mode"] 24

# # Edit TaskWarrior
# $TaskwarriorContent = Get-Content $Taskwarrior["Config"]
# $TaskwarriorContent = $TaskwarriorContent -replace $Taskwarrior["Pattern"],$TaskWarrior["$Mode"]
# $TaskwarriorContent | Set-Content $Taskwarrior["Config"]

# # Edit Clipse
# Copy-Item -Path $Clipse["$Mode"] -Destination $Clipse["Config"] -Force`

# # Edit Hyprland
# $Hyprland["$Mode"] | Out-File -FilePath $Hyprland["Config"] -Force
# & hyprctl reload
