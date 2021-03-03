
Param
(
  [Parameter (Mandatory= $true)]
  [String] $RG = ""
)
$status = "False"
# Ensures you do not inherit an AzContext in your runbook
Disable-AzureRmContextAutosave –Scope Process
$connectionName = "AzureRunAsConnection"
try
{
    # Get the connection "AzureRunAsConnection "
    $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         

    "Logging in to Azure..."
    Add-AzureRmAccount `
        -ServicePrincipal `
        -TenantId $servicePrincipalConnection.TenantId `
        -ApplicationId $servicePrincipalConnection.ApplicationId `
        -CertificateThumbprint   $servicePrincipalConnection.CertificateThumbprint 
}
catch {
    if (!$servicePrincipalConnection)
    {
        $ErrorMessage = "Connection $connectionName not found."
        throw $ErrorMessage
    } else{
        Write-Error -Message $_.Exception
        throw $_.Exception
    }
} 
#Start-AzVM -Name $VM -ResourceGroupName $RG -Confirm:$false
$alerts =  Get-AzureRMResource -ResourceGroupName $RG  | Where-Object{$_.ResourceType -EQ "microsoft.insights/webtests" -or $_.ResourceType -EQ "microsoft.insights/scheduledqueryrules" -or $_.ResourceType -EQ "microsoft.insights/metricalerts"}
ForEach ($alert in $alerts) { 
    $alert = Get-AzureRMResource -ResourceId $alert.Id
    $alert.Properties.Enabled = $status 
    $alert | Set-AzureRMResource -Force
}
