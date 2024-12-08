#!/usr/bin/env -S pwsh -NoProfile

<#
    Set-HyprlandTheme.ps1 - A PowerShell Script for Automating Hyprland Themes
    Copyright (C) 2024  BinaryInk

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

    Contact:
    - **Email:** 8i3ccfgkv@mozmail.com
    - **GitHub:** <https://www.github.com/BinaryInk/>
#>

using namespace System.Collections.Generic

[CmdletBinding(
    SupportsShouldProcess = $true
)]

param(
    # Theme mode to apply
    [Parameter(Mandatory = $true, Position = 0)]
    [string]
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
        if ($item.type -eq 'Change_Cursor' -or 
                $item.type -eq 'KDE_ColorScheme' -or
                $item.type -eq 'GTK_Theme') {
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
        Write-Host "Switching '$($item.appName)' to '$Mode' Mode..."

        if ($AppsNotFound -contains $item.appName) { continue }

        Write-Debug "Checking for user-provided preCommand..."
        if ($item.preCommand -ne "" -and
            $null -ne $item.preCommand) {
            Write-Verbose "Invoking user-provided preCommand '$($item.preCommand)'..."
            if ($WhatIfPreference -eq $true) {
                Write-Host "What if: Invoking expression: $($item.preCommand)"
            }
            else {
                try {
                    $output = Invoke-Expression -Command $item.preCommand
                }
                catch {
                    Write-Error "Unable to execute user-provided preCommand '$($item.preCommand)'."
                    Write-Host "preCommand Output: $output"
                    Write-Warning "Skipping $($item.appName)!"
                    continue
                }
            }
        }

        Write-Debug "$($item.appName) type: $($item.type)"
        switch ($item.type) {
            'Replace_FileContents' {
                try { $item.modes.$Mode | Out-File $item.path -WhatIf:$WhatIfPreference }
                catch { Write-Error "Unable to write to $($item.path)" }
            }
            'KDE_ColorScheme' {
                if (!$OptionalCliUtilities['plasma-apply-colorscheme']) {
                    $cmd = "plasma-apply-colorscheme $($item.modes.$Mode)"

                    if ($WhatIfPreference -eq $true) {
                        Write-Host "What if: Invoking expression: '$cmd'."
                    }
                    else {
                        try {
                            Write-Debug "Invoking expression: '$cmd'."
                            $output = Invoke-Expression $cmd
                            if ($LASTEXITCODE -ne 0) { throw }
                            Write-Host "plasma-apply-colorscheme: $output" 
                        }
                        catch { 
                            Write-Error "plasma-apply-colorscheme failed to set $($item.modes.$Mode)" 
                        }
                    }
                }
                else {
                    Write-Error 'KDE: Unable to set color scheme via plasma-apply-colorscheme!'
                }
            }
            'GTK_Theme' {
                if (!$OptionalCliUtilities['gsettings']) {
                    $cmd = "gsettings set org.gnome.desktop.interface gtk-theme '$($item.modes.$Mode)'"

                    if ($WhatIfPreference -eq $true) {
                        Write-Host "What if: Invoking expression: '$cmd'"
                    }
                    else {
                        try {
                            Write-Debug "Invoking expression: '$cmd'"
                            $output = Invoke-Expression $cmd
                            if ($LASTEXITCODE -ne 0) { throw }
                            if ($output) { Write-Host "gsettings: $output" }
                        }
                        catch {
                            Write-Error "gsettings failed to set GTK theme of '$($item.modes.$Mode)'"
                        }
                    }
                }
                else {
                    Write-Error 'GTK: Unable to set GTK theme via gsettings!'
                }
            }
            'Replace_File' {
                if (!$(Test-Path $item.modes.$Mode)) {
                    Write-Error "Config File Replacement: $($item.modes.$Mode) does not exist!"
                }
                else {
                    try {
                        Write-Verbose "Copying item '$($item.modes.$Mode)' to '$($item.path)' forcibly."
                        Copy-Item -Path $item.modes.$Mode `
                                  -Destination $item.path `
                                  -Force `
                                  -WhatIf:$WhatIfPreference
                    }
                    catch { 
                        Write-Error "Failed to overwrite $($item.path)"
                    }
                }
            }
            'Change_Cursor' {
                if (!$OptionalCliUtilities['gsettings']) {
                    $gsettingsMode = $($item.modes.$Mode).Split(' ')[0]
                    $cmd = "gsettings set org.gnome.desktop.interface cursor-theme $gsettingsMode"
                    if ($WhatIfPreference -eq $true) {
                        Write-Host "What if: Invoking expression: '$cmd'.)"
                    }
                    else {
                        try {
                            Write-Verbose "Invoking expression: '$cmd'."
                            $output = Invoke-Expression $cmd
                            if ($LASTEXITCODE -ne 0) { throw }
                            Write-Host "gsettings: $output"
                        }
                        catch {
                            Write-Error "Failed to set cursor via gsettings"
                        }
                    }
                }
                # TODO Handle KDE
                if ($WhatIfPreference -eq $true) {
                    Write-Host "What if: Invoking expression: '$cmd'."
                }
                else {
                    $cmd = "hyprctl setcursor $($item.modes.$Mode)"
                    try { 
                        Write-Verbose "Invoking expression: '$cmd'."
                        $output = Invoke-Expression $cmd
                        if ($LASTEXITCODE -ne 0) { throw }
                        Write-Host "hyprctl: $output"
                    }
                    catch { 
                        Write-Error "Failed to set cursor via hyprctl!"
                    }
                }
            }
            'Replace_Pattern' {
                Write-Verbose "Replacing contents of '$($item.path)' with '$($item.modes.$Mode)' using regex pattern of '$($item.pattern)'."
                $FileContent = Get-Content $item.path
                $FileContent = $FileContent -replace $item.pattern,$item.modes.$Mode
                $FileContent | Set-Content $item.path -WhatIf:$WhatIfPreference
            }
            Default {
                Write-Error "Unknown Config Type: '$($item.type)'."
            }
        }

        if ($item.postCommand -ne "" -and
            $null -ne $item.postCommand) {
            if ($WhatIfPreference -eq $true) {
                Write-Host "What if: Invoking expression: '$($item.preCommand)'."
            }
            else {
                try {
                    Write-Verbose "Invoking user-provided postCommand '$($item.postCommand)'."
                    $output = Invoke-Expression -Command $item.postCommand 
                }
                catch {
                    Write-Error "Unable to execute user-provided postCommand '$($item.postCommand)'."
                    Write-Host "postCommand output: $output"
                    Write-Warning "Please check the state of $($item.appName) due to this failure."
                    continue
                }
            }
        }
    }
}

end {}
