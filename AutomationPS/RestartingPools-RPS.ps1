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
 Write-Output "Creating remote command...."
$ServiceName = '$ServiceName '
$arrService = '$arrService'
$remoteCommand =
@"
$ServiceName = 'RPS Next Administration Service'
$arrService = Get-Service -Name $ServiceName

while ($arrService.Status -ne 'Running')
{

    Start-Service $ServiceName
    write-host $arrService.status
    write-host 'Service starting'
    Start-Sleep -seconds 60
    $arrService.Refresh()
    if ($arrService.Status -eq 'Running')
    {
        Write-Host 'Service is now Running'
    }

}
Restart-WebAppPool -Name RPSNextUpdaterAppPool
Restart-WebAppPool -Name RPSNextAppPool
Restart-WebAppPool -Name DefaultAppPool
"@
 Write-Output $remoteCommand
# Save the command to a local file
Set-Content -Path ".\DriveCommand.ps1" -Value $remoteCommand
 Write-Output "Invoking command...."
Invoke-AzVMRunCommand -ResourceGroupName $RG -VMName $VM -CommandId 'RunPowerShellScript' -ScriptPath '.\DriveCommand.ps1'
# Clean-up the local file
Remove-Item ".\DriveCommand.ps1"