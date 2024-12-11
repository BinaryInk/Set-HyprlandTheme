# Changelog

- [Changelog](#changelog)
  - [Version 1.0.2](#version-102)
    - [Features](#features)
    - [Changes](#changes)
  - [Version 1.0.1](#version-101)
    - [Features](#features-1)
  - [Version 1.0.0](#version-100)

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
