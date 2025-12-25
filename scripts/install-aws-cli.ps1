<#
install-aws-cli.ps1
PowerShell script to download and install AWS CLI v2 MSI on Windows.
Run this script from an elevated PowerShell prompt (Run as Administrator).
#>

# Check for elevation
If (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "This script must be run as Administrator. Right-click PowerShell and choose 'Run as Administrator'."
    exit 1
}

$msiUrl = 'https://awscli.amazonaws.com/AWSCLIV2.msi'
$msiPath = Join-Path $env:TEMP 'AWSCLIV2.msi'

Write-Output "Downloading AWS CLI v2 MSI to: $msiPath"
Invoke-WebRequest -Uri $msiUrl -OutFile $msiPath -UseBasicParsing

Write-Output "Running installer (msiexec)..."
$msiArgs = "/i `"$msiPath`" /qn"
$proc = Start-Process -FilePath msiexec.exe -ArgumentList $msiArgs -Wait -PassThru
if ($proc.ExitCode -ne 0) {
    Write-Error "msiexec finished with exit code $($proc.ExitCode). Try running the installer interactively or check installer logs."
    exit $proc.ExitCode
}

Write-Output "Installer finished. Removing the MSI file."
Remove-Item $msiPath -Force -ErrorAction SilentlyContinue

# Verify installation
Write-Output "Verifying 'aws --version'..."
$awsCmd = Get-Command aws -ErrorAction SilentlyContinue
if ($awsCmd) {
    & aws --version
    Write-Output "AWS CLI appears installed. You may need to restart your PowerShell session for PATH changes to take effect."
} else {
    Write-Warning "'aws' command not found in PATH. Checking default install location..."
    $defaultPath = 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'
    if (Test-Path $defaultPath) {
        Write-Output "Found aws.exe at $defaultPath. Adding to User PATH temporarily and printing version."
        $env:Path = $env:Path + ";C:\Program Files\Amazon\AWSCLIV2"
        & "$defaultPath" --version
        Write-Output "To make the PATH change permanent, run the following (as your user):"
        Write-Output "[Environment]::SetEnvironmentVariable('Path', $env:Path + ';C:\Program Files\Amazon\AWSCLIV2', 'User')"
    } else {
        Write-Error "AWS CLI not found. Installer may have failed. Try running the MSI interactively: msiexec /i "$msiPath""
        exit 2
    }
}

Write-Output "Done. Run 'aws --version' in a new PowerShell window to confirm, then 'aws configure' to set credentials if needed." 
