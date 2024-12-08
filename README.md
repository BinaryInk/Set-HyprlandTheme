# Set-HyprlandTheme.ps1

A PowerShell Script for Automating Themes in Hyprland

- [Set-HyprlandTheme.ps1](#set-hyprlandthemeps1)
  - [About](#about)
  - [Features](#features)
  - [Dependencies](#dependencies)
    - [Required](#required)
    - [Optional](#optional)
  - [How to use](#how-to-use)
    - [The Config File](#the-config-file)
      - [Properties](#properties)
      - [Mode purpose by type](#mode-purpose-by-type)
  - [Issues \& Contribution](#issues--contribution)
  - [Roadmap](#roadmap)
    - [List of Potential Improvements](#list-of-potential-improvements)

## About

This is a simple,  configurable PowerShell script to enable theme switching across various programs
in Hyprland. Instead of altering the script directly or managing a myriad of separate scripts, a
*.json configuration file is leveraged. The config can reside in one of three default locations or
be passed directly to the script via parameter.

## Features

The config file allows for the following configuration types:

- **Replace_FileContents**
  - Replaces *all of the contents* of a given file.
- **Replace_File**
  - Replaces a given file with another given file.
- **Replace_Pattern**
  - Replaces part(s) of a file using a regex pattern.
- **GTK_Theme**
  - Changes the theme preset for GTK. Currently, only one command, but may be expanded later; use
    the various *Replace* types above to modify CSS files.
- **KDE_ColorScheme**
  - Leverages a KDE application to change between different *.color files. These can be edited using
    the KDE System Settings application from within Hyprland and *shouldn't* require KDE Plasma to
    be installed, though I haven't tested what specific components of Plasma are required.
- **Change_Cursor**
  - Changes the mouse cursor. The target cursor must be installed to use and loose files cannot be
    used. This presently leverages Hyprcursor and GTK's gsettings application; this appears to cover
    all bases, but I have some ideas on how to expand this to be more thorough (e.g., persistence on
    restarts).

With the above types provided, one should be able to create a fairly thorough solution for their
setup. GTK and KDE provide the ability for QT and GTK apps to automatically adapt to the changes,
Change_Cursor covers the cursor in the live environment, and the three Replace_* types allow for
customized configurations for apps with their own theme files (such as Dunst or Rofi).

## Dependencies

### Required

- [Microsoft PowerShell 7](https://github.com/PowerShell/PowerShell)

### Optional

The script will not fail without these, but certain types may not work correctly without them or may
have no effect at all. This list has not been thoroughly tested and therefore is not exhaustive.

- [Hyprland](https://hyprland.org/) - In theory, Hyprland is not *required*, but it was made with
  Hyprland in mind.
- [gsettings](https://wiki.archlinux.org/title/Dark_mode_switching#GTK) - *Required* for the
  `GTK_Theme` type and *used* in the `Change_Cursors` type.
- `plasma-apply-colorscheme` - *Required* for the `KDE_ColorScheme` type.
- [Hyprcursor](https://wiki.hyprland.org/Hypr-Ecosystem/hyprcursor/) - *Used* in the
  `Change_Cursors` type to change the cursor.

NOTE: If both `gsettings` and Hyprcursor aren't installed, the `Change_Cursors` type  will have no
effect.

## How to use

1. Download the `Set-HyprlandTheme.ps1` script and place in a directory of your choosing.

### The Config File

See the included config file for my working config on how to set up. The config file will
automatically be picked up if it is in one of the following default locations (checked in this
order):

- $PSScriptRoot/config.json (i.e., in the same folder as the script)
- ~/.config/Set-HyprlandTheme/config.json
- ~/.config/hypr/Set-HyprlandTheme/config.json
- ~/.config/hypr/Set-HyprlandTheme.json

#### Properties

Each entry has a number of required properties based on the type of configuration:

| Property    | Purpose                                                                                                                                                                                                                                                                       | Required By Type(s)                                       |
|-------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------|
| appName     | Primarily visual for script feedback                                                                                                                                                                                                                                          | Not technically required, but strongly recommended.       |
| type        | Indicates the type of configuration this is                                                                                                                                                                                                                                   | All, as it indicates `type`                               |
| path        | Indicates the path to a given file that is to be used or edited directly. Typically a configuration file for a given application.                                                                                                                                             | `Replace_File`, `Replace_FileContents`, `Replace_Pattern` |
| modes       | A list of modes with a string whose purpose varies based on the provided `type`. See the table below this one. The name of the mode can be whatever you'd like and you can indicate as many modes as you'd like as well. Typically, though, these will be "Light" and "Dark". | All; at least two modes should be used.                   |
| preCommand  | An optional one-liner command that will be run prior to the primary action of the type                                                                                                                                                                                        | Not Required                                              |
| postCommand | An optional one-liner command that will be run after the primary action of the type; typically used for refreshing or restarting an application                                                                                                                               | Not Required                                              |
| pattern     | A regex pattern                                                                                                                                                                                                                                                               | `Replace_Pattern`                                         |

#### Mode purpose by type

Each type expects a slightly different string for a given mode:

| Type                 | Purpose                                                                                               |
|----------------------|-------------------------------------------------------------------------------------------------------|
| Replace_FileContents | The mode is the text that the contents of the file in the `path` property will be replaced with       |
| Replace_File         | The mode is the path of the file that will replace the file in the `path` property                    |
| Replace_Pattern      | The mode is the text that will be replaced using the regex pattern provided in the `pattern` property |
| GTK_Theme            | The mode is the name of the GTK theme to set                                                          |
| KDE_ColorScheme      | The mode is the name of the KDE Color Scheme to set                                                   |
| Change_Cursor        | The mode is the name of the installed cursor to apply to the system along with the size of the cursor |

## Issues & Contribution

Feel free to submit any issues or fixes via PR if you use this script and find any; if it is
germane to the goal of the script, I will look into fixing it it. If it is a feature request that
is outside of the scope of this project, I may put it on a to do list for the binary PowerShell
module I'm working on for Hyprland (see roadmap below).

**If you submit an issue, please provide the output from the script with the `-Verbose` and `-Debug`
parameters and provide the contents your configuration `json` file.**

## Roadmap

To preface: this script is provided as-is, and is more or less final, so there isn't much of a
roadmap.

*Eventually*, the functionality of this script will be folded into a PowerShell binary module that I
am working on.  The existence of this script predated that project and I wanted to have a more
solid concept of how I wanted to approach rewriting it in C#, so I worked to make this more of a
generalized project vs. a specific one for my own use (I was actively using the old hardcoded
predecessor to this script, occasionally adding new programs, and I desired a simple way to add
applications until the binary module is ready for use).

While this should be considered the final product, there are some limitations that I'm interested in
tackling that *may or may not* happen before the binary module is ready. Some of these improvements
will likely just be a command added to the `postCommand` property in the config file provided in
this repo.

### List of Potential Improvements

- Refreshing of open windows that use GTK for theming (e.g., Code, Firefox).  This is probably my
  top concern and annoyance at the moment. I'm not sure that this is something that GTK is capable
  of off-hand, but *am* interested in addressing it before I add this to the binary module if it is
  possible, as there are a lot of applications that seem to look for what mode GTK is in or
  leverage GTK's theme colors (e.g., VSCode, Firefox, Thunderbird, etc.)
  - (**NOTE:** QT apps *do* refresh when changed)
- Refreshing of open Kitty windows
- Support for non-KDE QT color switching (i.e., using qt6ct and/or qt5ct). Ideally, I'd like to
  eventually remove Plasma from my devices as I no longer use it.
- Wallpaper(s)
- Automated setup via systemd and/or cron:
  - Static times per day
  - Sunset auto-switching without use of a public API (offline).
    - This may wait until the binary module.
- Support for multiple paths, multiple values per mode for some of the types.
