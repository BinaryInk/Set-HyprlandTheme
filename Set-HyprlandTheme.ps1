#!/usr/bin/env -S pwsh -NoProfile

using namespace System.Collections.Generic

[CmdletBinding(
    SupportsShouldProcess = $true
)]

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
        if (which $cmd) {
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
        else {
            [string]$ConfigExtension = Get-ChildItem -Path $ConfigPath | 
                Select-Object -ExpandProperty 'Extension'
        }

        if ($ConfigExtension -ne '.json' -and
            $ConfigExtension -ne '.jsonc') {
            throw "Config file extension indicates the provided config file is not a json file."
        }
        Remove-Variable -Name 'ConfigExtension' 
    }

    Write-Debug "Loading config file ($ConfigPath)..."
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json }
    catch { throw 'Cannot load config JSON.' }

    Write-Debug "Checking config entries..."
    foreach ($item in $Config.applications) {
        Write-Debug "Checking config path for '$($item.appName)'..."
        if ($item.type -eq 'Cursor' -or $item.type -eq 'KDE') {
            Write-Debug "Config type '$($item.type)' has no path to check."
            continue
        }
        if (!$(Test-Path $item.path)) {
            Write-Warning "$($item.appName): Configuration file not found at '$($item.path)'!"
            $AppsNotFound.Add($item.appName)
        }
    }
}

process {
    foreach ($item in $Config.applications) {
        Write-Host "Switching $($item.appName) to $Mode Mode..."

        if ($AppsNotFound -contains $item.appName) { continue }

        Write-Debug "Checking for preCommand..."
        if ($item.preCommand -ne "" -and
            $null -ne $item.preCommand) {
            Write-Debug "Attempting to Run preCommand '$($item.preCommand)'..."
            if ($WhatIfPreference -eq $true) {
                Write-Host "What if: Invoking expression: $($item.preCommand)"
            }
            else {
                try {
                    Invoke-Expression -Command $item.preCommand
                }
                catch {
                    Write-Error "Unable to execute preCommand ($($item.preCommand))"
                    Write-Warning "Skipping switching $($item.appName)!"
                    continue
                }
            }
        }

        switch ($item.type) {
            'FileContents' {
                try { $item.mode.$Mode | Out-File $item.path -WhatIf:$WhatIfPreference }
                catch { Write-Error "Unable to write to $($item.path)" }
            }
            'KDE QT' {
                if ($OptionalCliUtilities['plasma-apply-colorscheme']) {
                    $cmd = "plasma-apply-colorscheme $($item.mode.$Mode)"

                    if ($WhatIfPreference -eq $true) {
                        Write-Host "What if: Invoking expression: $cmd"
                    }
                    else {
                        try { 
                            Invoke-Expression $cmd 
                        }
                        catch { 
                            Write-Error "plasma-apply-colorscheme failed to set $($item.mode.$Mode)" 
                        }
                    }
                }
                else {
                    Write-Error 'KDE QT: Unable to set color scheme via plasma-apply-colorscheme!'
                }
            }
            'ReplaceFile' {
                if (!$(Test-Path $item.mode.$Mode)) {
                    Write-Error "Config File Replacement: $($item.mode.$Mode) does not exist!"
                }
                else {
                    try { 
                        Copy-Item -Path $item.mode.$Mode `
                                  -Destination $item.path `
                                  -WhatIf:$WhatIfPreference `
                                  -Force
                    }
                    catch { Write-Error "Failed to overwrite $($item.path)" }
                }
            }
            'Cursor' {
                if ($OptionalCliUtilities['gsettings']) {
                    $cmd = "gsettings set org.gnome.desktop.interface cursor-theme $($item.mode.$Mode)"
                    if ($WhatIfPreference -eq $true) {
                        Write-Host "What if: Invoking expression: $cmd)"
                    }
                    else {
                        try {
                            Invoke-Expression $cmd
                        }
                        catch {
                            Write-Error "Failed to set cursor via gsettings"
                        }
                    }
                }
                # Handle KDE
                if ($WhatIfPreference -eq $true) {
                    Write-Host "What if: Invoking expression: $cmd"
                }
                else {
                    try { hyprctl setcursor $item.mode.$Mode}
                    catch { Write-Error "Failed to set cursor via hyprctl!"}
                }
            }
            'PatternReplace' {
                $FileContent = Get-Content $item.path
                $FileContent = $FileContent -replace $item.pattern,$item.mode.$Mode
                $FileContent | Set-Content $item.path -WhatIf:$WhatIfPreference
            }
            Default {
                Write-Error "Unknown Config Type: $($item.type)"
            }
        }

        if ($item.postCommand -ne "" -and
            $null -ne $item.postCommand) {
            Write-Debug "Attempting to Run postCommand '$($item.postCommand)'..."
            if ($WhatIfPreference -eq $true) {
                Write-Host "What if: Invoking expression: $($item.preCommand)"
            }
            else {
                try { 
                    Invoke-Expression -Command $item.postCommand 
                }
                catch {
                    Write-Error "Unable to execute postCommand ($($item.postCommand))"
                    Write-Warning "Please check the state of $($item.appName) due to this failure."
                    continue
                }
            }
        }
    }
}

end {}
