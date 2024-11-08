#!/usr/bin/env -S pwsh -NoProfile

param(
    # Theme mode to apply
    [Parameter(Mandatory = $false, Position = 0)]
    [string]
    [ValidateSet('Light','Dark')]
    $Mode
)

### Settings

$Hostname = Get-Content '/etc/hostname'

$Waybar = @{
    Type = 'Replace';
    Config = '~/.config/waybar/style.css';
    Light = 'style-light.css';
    Dark = 'style-dark.css';
}
$GtkCss = @{
    Type = 'Edit';
    Config = '~/.config/gtk-3.0/gtk.css';
    Light = 'colors-light.css';
    Dark = 'colors-dark.css';
}
$GtkIni = @{
    Type = 'Replace';
    Config = '~/.config/gtk-3.0/settings.ini'
    Light = '~/.config/gtk-3.0/settings-light.ini'
    Dark = '~/.config/gtk-3.0/settings-dark.ini'
}
$Qt = @{
    Type = '';
    Config = '';
    Light = 'HyprlandLight';
    Dark = 'BinaryInkBlack';
}
$Kitty = @{
    Type = 'Replace';
    Config = '~/.config/kitty/kitty.conf';
    Light = '~/.config/kitty/kitty-light.conf';
    Dark = '~/.config/kitty/kitty-dark.conf';
}
$Pwsh = @{
    Type = 'Edit';
    Config = '~/.config/powershell/powershell.d/00-env-theme.ps1';
    Light = '$env:PWSH_THEME_LIGHT = 1';
    Dark = '$env:PWSH_THEME_LIGHT = 0';
}
$Hyprland = @{
    Type = 'Edit';
    Config = '~/.config/hypr/hyprland.conf.d/theme-mode.conf';
    Light = '$themeMode=light';
    Dark = '$themeMode=dark';
}
$SuperProductivity = @{
    Type = 'Replace';
    Config = '~/.config/superProductivity/styles.css';
    Light = '~/.config/superProductivity/styles-light.css';
    Dark = '~/.config/superProductivity/styles-dark.css';
}
$Rofi = @{
    Type = 'Replace';
    Config = '~/.config/rofi/current.rasi';
    Light = '~/.config/rofi/light.rasi';
    Dark = '~/.config/rofi/dark.rasi';
}
$Dunst = @{
    Type = 'Replace';
    Config = '~/.config/dunst/dunstrc';
    Light = "~/.config/dunst/dunstrc_$($Hostname)_light"
    Dark = "~/.config/dunst/dunstrc_$($Hostname)_dark"
}
$Cursor = @{
    Type = 'Set'
    Light = 'Bibata-Modern-Ice'
    Dark = 'Bibata-Modern-Classic'
}
$Taskwarrior = @{
    Type = 'Edit'
    Config = "$HOME/.taskrc"
    Light = 'light-256.theme'
    Dark = 'dark-256.theme'
    Pattern = '(?<=^|\s)(\w+-\w+)\.theme(?=\s|$)'
}

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
# Edit Hyprland
$Hyprland["$Mode"] | Out-File -FilePath $Hyprland["Config"] -Force
# Edit superProductivity
Copy-Item -Path $SuperProductivity["$Mode"] -Destination $SuperProductivity["Config"] -Force
# Edit & restart dunst
Copy-Item -Path $Dunst["$Mode"] -Destination $Dunst["Config"]
killall dunst
systemctl start dunst --user
# Edit rofi
Copy-Item -Path $Rofi["$Rofi"] -Destination $Dunst["Config"]
# Edit Cursor
gsettings set org.gnome.desktop.interface cursor-theme $Cursor["$Mode"]
hyprctl setcursor $Cursor["$Mode"] 24
# Edit TaskWarrior
Get-Content $Taskwarrior.Config | 
    ForEach-Object { $_ -replace $Taskwarrior["Pattern"],$TaskWarrior["$Mode"] } |
    Set-Content
