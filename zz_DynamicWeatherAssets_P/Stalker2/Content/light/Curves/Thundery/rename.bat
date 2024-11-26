@echo off
Setlocal enabledelayedexpansion

Set "Pattern=Thundery"
Set "Replace=Thundery"

For %%# in ("D:\fmod\Output\Exports\Stalker2\Content\light\Curves\Thundery\*.json") Do (
    Set "File=%%~nx#"
    Ren "%%#" "!File:%Pattern%=%Replace%!"
)

Pause&Exit