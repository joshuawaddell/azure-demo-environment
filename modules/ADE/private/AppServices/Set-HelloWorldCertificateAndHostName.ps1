function Set-HelloWorldCertificateAndHostName {
    param(
        [object] $armParameters
    )

    Write-ScriptSection "Initializing Set-HelloWorldCertificateAndHostName Deployment"

    $rootDomainName = $armParameters.rootDomainName
    $fqdn = "helloworld."+$rootDomainName
    $keyVaultName = $armParameters.keyVaultName
    $certName = 'pfx-certificate'
    $primaryRegionHelloWorldWebAppResourceGroupName = $armParameters.primaryRegionHelloWorldWebAppResourceGroupName
    $primaryRegionHelloWorldWebAppName = $armParameters.primaryRegionHelloWorldWebAppName
    $secondaryRegionHelloWorldWebAppResourceGroupName = $armParameters.secondaryRegionHelloWorldWebAppResourceGroupName
    $secondaryRegionHelloWorldWebAppName = $armParameters.secondaryRegionHelloWorldWebAppName

    Write-Log "Configuring Host Name Binding to Primary Region Hello World Web App"
    az webapp config hostname add -g $armParameters.primaryRegionHelloWorldWebAppResourceGroupName --webapp-name $armParameters.primaryRegionHelloWorldWebAppName --hostname $fqdn
    Confirm-LastExitCode

    Write-Log "Configuring Host Name Binding to Secondary Region Hello World Web App"
    az webapp config hostname add -g $armParameters.secondaryRegionHelloWorldWebAppResourceGroupName --webapp-name $armParameters.secondaryRegionHelloWorldWebAppName --hostname $fqdn
    Confirm-LastExitCode

    Write-Log "Importing Key Vault Certificate to Primary Region Hello World Web App"
    az webapp config ssl import --resource-group $primaryRegionHelloWorldWebAppResourceGroupName --name $primaryRegionHelloWorldWebAppName --key-vault $keyVaultName --key-vault-certificate-name $certName
    Confirm-LastExitCode

    Write-Log "Importing Key Vault Certificate to Secondary Region Hello World Web App"
    az webapp config ssl import --resource-group $secondaryRegionHelloWorldWebAppResourceGroupName --name $secondaryRegionHelloWorldWebAppName --key-vault $keyVaultName --key-vault-certificate-name $certName
    Confirm-LastExitCode

    Write-Log "Retrieving Thumbprint for Certificate from Key Vault"
    $Thumbprint = az keyvault certificate show --name $certName --vault-name $keyVaultName --query x509ThumbprintHex --output tsv

    # TODO: Disabled until Azure CLI Issue 13929 resolved - https://github.com/Azure/azure-cli/issues/13929
    # az webapp config ssl bind --certificate-thumbprint $Thumbprint --name $primaryRegionHelloWorldWebAppName --resource-group $primaryRegionHelloWorldWebAppResourceGroupName --ssl-type SNI

    Write-Log "Binding Key Vault Certificate to Primary Region Hello World Web App"
    New-AzWebAppSSLBinding -ResourceGroupName $primaryRegionHelloWorldWebAppResourceGroupName -WebAppName $primaryRegionHelloWorldWebAppName -Thumbprint $Thumbprint -Name $fqdn -SslState SniEnabled
    Confirm-LastExitCode

    Write-Log "Binding Key Vault Certificate to Secondary Region Hello World Web App"
    New-AzWebAppSSLBinding -ResourceGroupName $secondaryRegionHelloWorldWebAppResourceGroupName -WebAppName $secondaryRegionHelloWorldWebAppName -Thumbprint $Thumbprint -Name $fqdn -SslState SniEnabled
    Confirm-LastExitCode

    Write-Status "Finished Set-HelloWorldCertificateAndHostName Deployment"
}







