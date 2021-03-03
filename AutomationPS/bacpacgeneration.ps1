
Param
(
  [Parameter (Mandatory= $false)]
  [String] $Server = "sqlrps",
  [Parameter (Mandatory= $false)]
  [String] $RG = "rps",
  [Parameter (Mandatory= $false)]
  [String] $Database = "RPSNext",
  [Parameter (Mandatory= $false)]
  [String] $DatabaseUser = "rpsadmin",
  [Parameter (Mandatory= $false)]
  [String] $DatabasePassword = "Ibermatica2020."
)

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave –Scope Process
# Gets the connection of the automation
$connection = Get-AutomationConnection -Name AzureRunAsConnection

#creates a credential to the Ibermatica tenant for a service principal
$password = ConvertTo-SecureString "h.W_.4v~zJr8dCEgpqyV2zw~Ta0EZk36so" -AsPlainText -Force
Write-Output "Creating credentials"
$psCredential = New-Object System.Management.Automation.PSCredential("3f4cbfc0-1bcf-468c-94ee-8d6dc44b67a2", $password)
#connects to ibermatica
$logonAttemptIbermatica = 0
while(!($connectionResultIbermatica) -And ($logonAttemptIbermatica -le 10))
{
    $logonAttemptIbermatica++
    Write-Output "Trying to connect with ibermatica suscription"
    $connectionResultIbermatica = Connect-AzAccount -ServicePrincipal -Credential $psCredential -Tenant "77403ad5-64df-482d-bf32-242c2fc1c290"
    Start-Sleep -Seconds 30
}
if(($connectionResultIbermatica))
{
    #retrieves the storage account url and sas token
    Write-Output $connectionResultIbermatica
    Write-Output "Connected to ibermatica"
    $baseUriObject = Get-AzKeyVaultSecret -vaultName "RPSDacpacKV" -name "BlobUri" -defaultProfile $connectionResultIbermatica
    $sastokenObject = Get-AzKeyVaultSecret -vaultName "RPSDacpacKV" -name "SASToken" -defaultProfile $connectionResultIbermatica
    $baseUri = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($baseUriObject.SecretValue))
    $sastoken= [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sastokenObject.SecretValue))
  
    #connects to the automation tenat
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
    if($connectionResult)
    {
        Write-Output "Connected to automation tenant"
        $Customer = Get-AutomationVariable -Name 'Customer'
        Write-Output $Customer
        #creates the uri
        
        $str1 = $baseUri
        $filename = "/database.bacpac"
        $strUrl = $str1+$Customer+$filename
        Write-Output $strUrl
        $deleteUrl = $strUrl + $SASToken
        #deletes previous files, if there are no files an error will appear
        Write-Output "Deleting previous files"
        $deleteIncidentResponse = Invoke-RestMethod -Method DELETE -Uri $deleteUrl
        Write-Output $deleteIncidentResponse
        #generates and deploys the bacpac to the storage account
        Write-Output "Generating bacpac"
        $Secure_String_Pwd = ConvertTo-SecureString $DatabasePassword -AsPlainText -Force
        New-AzSqlDatabaseExport -ResourceGroupName $RG -ServerName $Server -DatabaseName $Database -StorageKeyType "SharedAccessKey" -StorageKey $sastoken -StorageUri $strUrl -AdministratorLogin $DatabaseUser -AdministratorLoginPassword $Secure_String_Pwd
    }else{
        Write-Output "Error Connecting to automation tenant"    
    }

}else{
    Write-Output "Error Connecting to ibermatica"
}


