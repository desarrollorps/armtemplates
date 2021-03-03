Param
(
  [Parameter (Mandatory= $false)]
  [String] $VM = "rpsvmweu",
  [Parameter (Mandatory= $false)]
  [String] $RG = "rps"
)
$connection = Get-AutomationConnection -Name AzureRunAsConnection
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    Write-Output "Trying to connect to automation tenant...."
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                            -ServicePrincipal `
                            -Tenant $connection.TenantID `
                            -ApplicationId $connection.ApplicationID `
                            -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}

# Build a command that will be run inside the VM.
$remoteCommand =
@"
Restart-WebAppPool -Name RPSNextUpdaterAppPool
Restart-WebAppPool -Name RPSNextAppPool
Restart-WebAppPool -Name DefaultAppPool
"@
# Save the command to a local file
Set-Content -Path ".\DriveCommand.ps1" -Value $remoteCommand
Invoke-AzVMRunCommand -ResourceGroupName $RG -VMName $VM -CommandId 'RunPowerShellScript' -ScriptPath '.\DriveCommand.ps1'
# Clean-up the local file
Remove-Item ".\DriveCommand.ps1"