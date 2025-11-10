# UAChaos

This PowerShell script is a proof-of-concept (PoC) demonstrating various known User Account Control (UAC) bypass methods in Windows. It enables testing of multiple techniques to execute commands with elevated (administrator) privileges without triggering a UAC prompt.

> Supports executing individual methods such as `fodhelper`, `eventvwr`, `computerdefaults`, `sdclt`, `wsreset`, `mmc`, `eudcedit`, `netplwiz`, or running all sequentially until one succeeds.

---

<img width="1387" height="492" alt="grafik" src="https://github.com/user-attachments/assets/2e1c1400-e2a6-4628-bcdd-2b80dfab05ba" />


## Features

- Manipulates registry keys to hijack system processes for privilege elevation.
- Launches the corresponding system executable tied to each bypass method.
- Cleans up registry entries after execution.
- Accepts a custom command to run elevated (default is `cmd.exe`).
- Includes a method to create a ***SYSTEM*** process.
- Runs UAC Bypass with ***RUNASINVOKER*** variable.
- Uses ***UAC-Prompt-Bombing Attack*** seen here: [Article: New Botnet Emerges from the Shadows: NightshadeC2](https://www.esentire.com/blog/new-botnet-emerges-from-the-shadows-nightshadec2)

## Supported Methods

| Method           | Description                            | Status (2025)                                               |
|------------------|------------------------------------|-------------------------------------------------------------|
| fodhelper        | Registry-based bypass with fodhelper.exe | Works reliably on current Windows 10 and 11                  |
| eventvwr         | Event Viewer registry bypass          | Works reliably on Windows 7                                          |
| computerdefaults | Registry-based bypass with computerdefaults.exe | Works reliably on current Windows 10 and 11                                            |
| sdclt            | Registry-based bypass with sdclt.exe  | Mostly patched, often non-functional                       |
| wsreset          | Limited functionality with wsreset.exe | Works depending on system configuration                     |
| mmc              | Limited functionality with mmc.exe    | Works under specific conditions                             |
| eudcedit         | Limited functionality with eudcedit.exe | Works under specific conditions                             |
| netplwiz         | Limited functionality with netplwiz.exe | Works under specific conditions                             |
| all              | Runs all methods sequentially          | Attempts all methods until one succeeds                     |

## Requirements

- Windows 7 or later.
- Localgroup `Administrators` privileges. Check/Add with `net localgroup Administrators user /add`
- PowerShell with permissions to modify registry keys and execute scripts.
- On most current Windows versions, some bypass methods are patched; `fodhelper` and `eventvwr` are generally still effective.

## Quick Start

```powershell
# For Hiding the Banner and UAChaos output use: -WindowStyle Hidden
powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "& {.\UAChaos.ps1 -Method computerdefaults -Command 'cmd'}"
```

## Usage Examples

```powershell
# Run a single method (computerdefaults) with default elevated command (cmd.exe)
.\UAChaos.ps1 -Method computerdefaults

# Run a single method (computerdefaults) with command payload.exe as SYSTEM (Hidden)
.\UAChaos.ps1 -Method computerdefaults -Command "C:\Temp\payload.exe" -GetSystem

# Run UAC-Prompt-Bombing File. No Commands yet!
.\UAChaos.ps1 -UACBombing -Command "C:\Temp\payload_cmd.exe"

# Run RUNASINVOKER UAC Bypass with Commands
.\UAChaos.ps1 -RunAsInvoker -Command "mmc"

# Run all methods sequentially
.\UAChaos.ps1 -Method all

# Run fodhelper with a custom command (e.g., PowerShell)
.\UAChaos.ps1 -Method fodhelper -Command "powershell.exe -NoProfile"
```

### Run method (`computerdefaults`) with command `cmd.exe` in foreground as SYSTEM

- Needs MSDT Tools signed by MS (ServiceUI.exe)
- Check first with `query user` your Session ID

```powershell
.\UAChaos.ps1 -Method computerdefaults -Command "C:\Temp\ServiceUI.exe -session:2 C:\Windows\System32\cmd.exe" -GetSystem
```

## Disclaimer and Responsibility

- This script is intended strictly for educational and authorized testing purposes.
- UAC bypass techniques circumvent security controls and must only be used with explicit permission.
- Unauthorized use may violate laws and policies.
- Use responsibly and ethically.

## IMPORTANT NOTE

This Script is at the moment alpha with maybe many bugs. If you find some and want to contribute, please write an issue

***
