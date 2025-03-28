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

<#
.Synopsis
  Changes themes according to settings specified in a specially-crafted JSON
  file.

.Description
  Changes various theme files and executes specific commands defined in a JSON
  file. This can include custom scripts and commands, in addition to leveraging
  commandline applications such as 'gsettings' directoy.

.Parameter Mode
  The mode to change the theme to. The Mode specified must be included in each
  entry in the configuration JSON file.

.Parameter ConfigPath
  The path to the configuration JSON file.

.Example
  # Run with implicit config file, setting the theme mode to 'Dark'
  ./Set-HyprlandTheme.ps1 Dark

.Example
  # Run specifying the location of the config file, setting the theme mode to 'MyTheme'
  ./Set-HyprlandTheme.ps1 -Mode 'MyTheme' -Config '~/.myConfig.json'

.Example
  # Run with verbose output
  ./Set-HyprlandTheme.ps1 Dark -Verbose

.Example
  # Dry run using -WhatIf
  ./Set-HyprlandTheme.ps1 Dark -WhatIf

.Example
  # Dot-source the function from the script (Important: You must provide a value for -Mode)
  . ./Set-HyprlandTheme.ps1 FillerValue
  # Run the imported function.
  Set-HyprlandTheme Dark
#>
using namespace System.Collections.Generic
param(
  # Theme mode to apply
  [Parameter(
    Mandatory = $true, 
    Position = 0,
    HelpMessage = 'The mode to switch to (as defined in config.json)')]
  [string]
  $Mode,

  # Config file path
  [Parameter(
    Mandatory = $false, 
    Position = 1,
    HelpMessage = 'Path to configuration file')]
  [string]
  $ConfigPath
)

<#
.Synopsis
  Changes themes according to settings specified in a specially-crafted JSON
  file.

.Description
  Changes various theme files and executes specific commands defined in a JSON
  file. This can include custom scripts and commands, in addition to leveraging
  commandline applications such as 'gsettings' directoy.

.Parameter Mode
  The mode to change the theme to. The Mode specified must be included in each
  entry in the configuration JSON file.

.Parameter ConfigPath
  The path to the configuration JSON file.

.Example
  # Run with implicit config file, setting the theme mode to 'Dark'
  Set-HyprlandTheme.ps1 Dark

.Example
  # Run specifying the location of the config file, setting the theme mode to 'MyTheme'
  Set-HyprlandTheme.ps1 -Mode 'MyTheme' -Config '~/.myConfig.json'

.Example
  # Run with verbose output
  Set-HyprlandTheme.ps1 Dark -Verbose

.Example
  # Dry run using -WhatIf
  Set-HyprlandTheme.ps1 Dark -WhatIf
#>
function Set-HyprlandTheme {
  [CmdletBinding(
    SupportsShouldProcess = $true
  )]

  param(
    # Theme mode to apply
    [Parameter(
      Mandatory = $true, 
      Position = 0,
      HelpMessage = 'The mode to switch to (as defined in config.json)')]
    [string]
    $Mode,

    # Config file path
    [Parameter(
      Mandatory = $false, 
      Position = 1,
      HelpMessage = 'Path to configuration file')]
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
    $OptionalCliUtilities = [Dictionary[string, bool]]::new()
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

    Write-Debug 'Checking for config file...'
    if (!$ConfigPath) {
      Write-Debug 'Config file path not provided. Checking default locations...'
      foreach ($path in $DefaultConfigPaths) {
        if (Test-Path $path) {
          Write-Debug "Found config file: '$path'"
          $ConfigPath = $path
        }
      }
    }
    else {
      Write-Debug 'Config file path provided. Checking for existence and validity...'
      if (!$(Test-Path $ConfigPath)) {
        throw "Config not found: '${Config}'"
      }
      else {
        [string]$ConfigExtension = Get-ChildItem -Path $ConfigPath | 
          Select-Object -ExpandProperty 'Extension'
      }

      if ($ConfigExtension -ne '.json' -and
        $ConfigExtension -ne '.jsonc') {
        throw 'Config file extension indicates the provided config file is not a json file.'
      }
      Remove-Variable -Name 'ConfigExtension'
    }

    Write-Debug "Loading config file ($ConfigPath)..."
    try { $Config = Get-Content $ConfigPath | ConvertFrom-Json }
    catch { throw 'Cannot load config JSON.' }

    Write-Debug "Configuration Settings: $Config"

    Write-Debug 'Checking config entries...'
    foreach ($item in $Config.applications) {
      Write-Debug "Checking config path for '$($item.appName)'..."
      if ($item.type -eq 'Change_Cursor' -or 
        $item.type -eq 'KDE_ColorScheme' -or
        $item.type -eq 'GTK_Theme') {
        Write-Debug "Config type '$($item.type)' has no path(s) to check."
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

      Write-Debug 'Checking for user-provided preCommand...'
      if ($item.preCommand -ne '' -and
        $null -ne $item.preCommand) {
        if ($PSCmdlet.ShouldProcess('This Computer', "Invoke Expression: ""$($item.preCommand)""")) {
          try {
            Write-Verbose "Invoking user-provided preCommand '$($item.preCommand)'..."
            Write-Host "precommand: $(Invoke-Expression -Command $item.preCommand `
                                                                    -Verbose:$VerbosePreference `
                                                                    -Debug:$DebugPreference )"
          }
          catch {
            Write-Error "Unable to execute user-provided preCommand '$($item.preCommand)'."
            Write-Warning "Skipping $($item.appName)!"
            continue
          }
        }
      }

      Write-Debug "$($item.appName) type: $($item.type)"
      switch ($item.type) {
        'Replace_FileContents' {
          if ($PSCmdlet.ShouldProcess($item.path, 'Out-File')) {
            try { 
              $item.modes.$Mode | 
                Out-File $item.path -Force `
                  -Verbose:$VerbosePreference `
                  -Debug:$DebugPreference
            }
            catch { 
              Write-Error "Unable to write to $($item.path)" 
            }
          }
        }
        'KDE_ColorScheme' {
          if (!$OptionalCliUtilities['plasma-apply-colorscheme']) {
            $cmd = "plasma-apply-colorscheme $($item.modes.$Mode)"
            if ($PSCmdlet.ShouldProcess('KDE', "Apply ""$Mode"" Color Scheme")) {
              try {
                Write-Debug "Invoking expression: '$cmd'."
                Write-Host "plasma-apply-colorscheme: $(Invoke-Expression $cmd `
                                                                            -Verbose:$VerbosePreference `
                                                                            -Debug:$DebugPreference)"
                if ($LASTEXITCODE -ne 0) { throw } 
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
            if ($PSCmdlet.ShouldProcess('GTK', """$Mode"" Theme")) {
              try {
                Write-Debug "Invoking expression: '$cmd'."
                Write-Host "gsettings: $(Invoke-Expression $cmd -Verbose:$VerbosePreference `
                                                                                -Debug:$DebugPreference)"
                if ($LASTEXITCODE -ne 0) { throw }
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
          if ($PSCmdlet.ShouldProcess($item.path, 'Replace file')) {
            if (!$(Test-Path $item.modes.$Mode)) {
              Write-Error "Config File Replacement: $($item.modes.$Mode) does not exist!"
            }
            else {
              try {
                Copy-Item -Path $item.modes.$Mode `
                  -Destination $item.path `
                  -Force `
                  -Verbose:$VerbosePreference `
                  -Debug:$DebugPreference
              }
              catch { 
                Write-Error "Failed to overwrite $($item.path)"
              }
            }
          }
        }
        'Change_Cursor' {
          if (!$OptionalCliUtilities['gsettings']) {
            $gsettingsMode = $($item.modes.$Mode).Split(' ')[0]
            $cmd = "gsettings set org.gnome.desktop.interface cursor-theme $gsettingsMode"
            if ($PSCmdlet.ShouldProcess('GTK Cursor', "Set Cursor to $gsettingsMode")) {
              try {
                Write-Verbose "Invoking expression: '$cmd'."
                Write-Host "gsettings: $(Invoke-Expression $cmd -Verbose:$VerbosePreference `
                                                                                -Debug:$DebugPreference)"
                if ($LASTEXITCODE -ne 0) { throw }
              }
              catch {
                Write-Error "Failed to set cursor of ""$gsettingsMode"" via gsettings"
              }
            }
          }
          # TODO Handle KDE
          if ($PSCmdlet.ShouldProcess('Hyprcursor', "Set Cursor to $($item.modes.$Mode)")) {
            $cmd = "hyprctl setcursor $($item.modes.$Mode)"
            try { 
              Write-Verbose "Invoking expression: '$cmd'."
              Write-Host 'hyprctl: ' -NoNewline
              Invoke-Expression $cmd -Verbose:$VerbosePreference `
                -Debug:$DebugPreference
              if ($LASTEXITCODE -ne 0) { throw }
            }
            catch { 
              Write-Error 'Failed to set cursor via hyprctl!'
            }
          }
        }
        'Replace_Pattern' {
          if ($PSCmdlet.ShouldProcess(
              $item.path, 
              "Replace contents with ""$($item.modes.$Mode)""  using regex pattern ""$($item.pattern)""")
          ) {
            $FileContent = Get-Content $item.path
            $FileContent = $FileContent -replace $item.pattern, $item.modes.$Mode
            $FileContent | 
              Set-Content $item.path -Force `
                -Verbose:$VerbosePreference `
                -Debug:$DebugPreference
          }
        }
        'SymLink' {
          if ($PSCmdlet.ShouldProcess(
              $item.path,
              "Replace file or symbolic link with `"$($item.modes.$($Mode))`".")
          ) {
            New-Item -ItemType SymbolicLink -Path $item.path -Value $item.modes.$Mode -Force
          }
        }
        Default {
          Write-Error "Unknown Config Type: '$($item.type)'."
        }
      }

      if ($item.postCommand -ne '' -and
        $null -ne $item.postCommand) {
        if ($PSCmdlet.ShouldProcess('This Computer', "Invoke Expression: ""$($item.postCommand)""")) {
          try {
            Write-Verbose "Invoking user-provided postCommand '$($item.postCommand)'."
            Write-Host "postCommand: $(Invoke-Expression -Command $item.postCommand `
                                                                    -Verbose:$VerbosePreference `
                                                                    -Debug:$DebugPreference)"
          }
          catch {
            Write-Error "Unable to execute user-provided postCommand '$($item.postCommand)'."
            Write-Warning "Please check the state of $($item.appName) due to this failure."
            continue
          }
        }
      }
    }
  }

  end {}
}

# Allow for importing or direct execution
if ($MyInvocation.InvocationName -eq '.') {
  Write-Verbose '''Set-HyprlandTheme'' added to current session scope.'
} 
else {
  Set-HyprlandTheme @PSBoundParameters
}
