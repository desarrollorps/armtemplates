
Param
(
  [Parameter (Mandatory= $true)]
  [String] $VM = "",
  [Parameter (Mandatory= $true)]
  [String] $RG = ""
)
# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process

$connection = Get-AutomationConnection -Name AzureRunAsConnection
while(!($connectionResult) -And ($logonAttempt -le 10))
{
    $LogonAttempt++
    # Logging in to Azure...
    $connectionResult =    Connect-AzAccount `
                               -ServicePrincipal `
                               -Tenant $connection.TenantID `
                               -ApplicationId $connection.ApplicationID `
                               -CertificateThumbprint $connection.CertificateThumbprint

    Start-Sleep -Seconds 30
}
Start-AzVM -Name $VM -ResourceGroupName $RG -Confirm:$false