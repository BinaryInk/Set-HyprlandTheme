# Changelog

- [Changelog](#changelog)
  - [Version 1.2.1](#version-121)
  - [Version 1.2.0](#version-120)
  - [Version 1.1.1](#version-111)
  - [Version 1.1.0](#version-110)
  - [Version 1.0.2](#version-102)
    - [Features](#features)
    - [Changes](#changes)
  - [Version 1.0.1](#version-101)
    - [Features](#features-1)
  - [Version 1.0.0](#version-100)

## Version 1.2.1

- Fixed `$DebugPreferences`/`$VerbosePreferences` check from `Continue` to
  `SilentlyContinue` when `-Quiet` or `-Silent` is passed.
- Removed hybrid script/dot-sourcing functionality
  - It turns out this only worked in an interactive session, thus could not be
    dot-sourced via script (i.e., profile). Rather than maintain it or attempt
    to find a fix, removing altogether as it was a somewhat hacky solution to
    begin with.
- Removed `-NoNewLine` from a `Write-Verbose` call that used to be a
  `Write-Host` call, introduced in 1.2.0.

## Version 1.2.0

**2025-04-23**

- Added `-Quiet` switch: Prevents output of app names when as are processed.
- Added `-Silent` switch: Prevents all stdout output; implies `-Quiet`
- Stdout cleaned up:
  - Moved stdout from 'Invoke-Expression' commands (e.g., preCommand,
    postCommand, etc.) to verbose output
  - Sent output from 'SymLink' to null, offer a similar, shorter message via
    Verbose
  - Changed messaging to only mention the mode being changed to once and instead
    only show the appname per-app
- For 'SymLink', `Resolve-Path` is now used to create a fully qualified path
  when executing `New-Item` so aliases like `~` can be used in paths without
  resulting in an invalid symbolic link.

## Version 1.1.1

**2025-04-22**

- `config.json`
  - Changed Dunst to symlink, updated path
  - Added Thunderbird

## Version 1.1.0

**2025-03-27**

- Added 'SymLink' type for creating symbolic links (alternative to Replace_File)

## Version 1.0.2

**2024-12-11**

### Features

- Added ability to either dot-source the script into a session or execute
  directly.
  - (**NOTE:** Requires filling out mandatory parameter(s) when dot-sourcing)
- Added proper support for ShouldProcess; should behave more uniformly and
  follows best practices:
  - `-Verbose` better supported: messages should be more consistent.
  - `-WhatIf` better supported: explicitly defined on all commands.
  - `-Debug` better supported: pauses to confirm execution of commands.
- Added help messages to parameters.
- Added `Get-Help` documentation for using script directly.
- Added `Get-Help` documentation to function (for dot-sourcing).

### Changes

- Updated `config.json`
  - Added 'GTK4-css' and 'GTK3-css'
  - Moved 'GTK' above custom GTK* edits to ensure they're not overwritten (left
    in as an example more than anything)

## Version 1.0.1

**2024-12-08**

### Features

- Removed constraint on `-Mode` parameter to allow for custom mode names outside
  of just 'Light' and 'Dark'.

## Version 1.0.0

**2024-12-07**

- Initial release.
