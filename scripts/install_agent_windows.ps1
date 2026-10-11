<#
    install_agent_windows.ps1
    Install and enroll a Wazuh agent on a Windows endpoint.
    Run in an ELEVATED PowerShell (Run as Administrator) on the endpoint to monitor.

    Usage:
        .\install_agent_windows.ps1 -ManagerIP 192.168.56.10 -AgentName win-ep-01 [-WazuhVersion 4.9]

    Docs: https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-windows.html
#>

param(
    [Parameter(Mandatory = $true)]  [string] $ManagerIP,
    [Parameter(Mandatory = $false)] [string] $AgentName    = $env:COMPUTERNAME,
    [Parameter(Mandatory = $false)] [string] $WazuhVersion = "4.9"
)

$ErrorActionPreference = "Stop"

# Require administrator
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script in an elevated (Administrator) PowerShell."
    exit 1
}

# Resolve the latest patch version of the chosen minor line (e.g. 4.9.x)
$msi  = "wazuh-agent-$WazuhVersion-1.msi"
$url  = "https://packages.wazuh.com/$($WazuhVersion.Split('.')[0]).x/windows/$msi"
$dest = Join-Path $env:TEMP $msi

Write-Host "[*] Downloading $url ..."
Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing

Write-Host "[*] Installing Wazuh agent (manager=$ManagerIP, name=$AgentName) ..."
$args = "/i `"$dest`" /q WAZUH_MANAGER=`"$ManagerIP`" WAZUH_AGENT_NAME=`"$AgentName`" WAZUH_REGISTRATION_SERVER=`"$ManagerIP`""
Start-Process -FilePath "msiexec.exe" -ArgumentList $args -Wait

Write-Host "[*] Starting the Wazuh service ..."
Start-Service -Name WazuhSvc

Write-Host ""
Write-Host "[+] Done. Confirm the agent is 'Active' on the dashboard (Agents view)."
Write-Host "    Then merge config\ossec.conf.windows.xml into:"
Write-Host "      C:\Program Files (x86)\ossec-agent\ossec.conf"
Write-Host "    and restart:  Restart-Service -Name WazuhSvc"
