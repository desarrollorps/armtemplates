$customer = "Finestra"
$rootcertname = "CN="+$customer+"IbermaticaP2SRootCert"
$childcertname = "CN="+$customer+"IbermaticaP2SChildCert"
$cert = New-SelfSignedCertificate -Type Custom -KeySpec Signature `
-Subject $rootcertname  -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 `
-CertStoreLocation "Cert:\CurrentUser\My" -KeyUsageProperty Sign -KeyUsage CertSign

New-SelfSignedCertificate -Type Custom -DnsName P2SChildCert -KeySpec Signature `
-Subject $childcertname -KeyExportPolicy Exportable `
-HashAlgorithm sha256 -KeyLength 2048 -NotAfter (Get-Date).AddYears(50) `
-CertStoreLocation "Cert:\CurrentUser\My" `
-Signer $cert -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")