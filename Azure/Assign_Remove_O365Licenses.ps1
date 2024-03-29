$cred = Get-Credential
Connect-MsolService -Credential $cred
Connect-AzureAD -Credential $cred

Get-MsolAccountSku #list of licenses available in your tenant

#Assign license all unlicensed and active users
$users = Get-MsolUser -All -UnlicensedUsersOnly | Select UserPrincipalName ,BlockCredential

foreach ($user in $users)
{
    $PrincipalName=$user.UserPrincipalName 
    $accountEnabled = (Get-AzureADUser -ObjectId $PrincipalName).AccountEnabled

    #If the user does not hevae license, assign new license
    if($accountEnabled -eq "true") {

        try{
            Set-MsolUser -UserPrincipalName $PrincipalName -UsageLocation TR
            Set-MsolUserLicense -UserPrincipalName $PrincipalName -AddLicenses “TENANT:LICENSE” -ErrorAction Stop
            Write-Host "O365 license assigned to $PrincipalName"
        }
        catch [System.Exception] {
            $LicenseAssignmentResult = "Assigning license failed."
            "Failed to assign license: {0}" -f  $_.Exception.Message
        }
    }
}

#Remove license from disabled users
$users = Get-MsolUser -All | Select UserPrincipalName ,BlockCredential
foreach ($user in $users)
{
    $PrincipalName=$user.UserPrincipalName 

    if((Get-MsolUser -UserPrincipalName $PrincipalName | select -ExpandProperty BlockCredential) -eq "true") {

        #Removing licenses from user accounts
        try{
            (get-MsolUser -UserPrincipalName $PrincipalName).licenses.AccountSkuId | ForEach-Object { Set-MsolUserLicense -UserPrincipalName $PrincipalName -RemoveLicenses $_ -ErrorAction Stop } 
            
            Write-Host "O365 license removed from $PrincipalName"
            $LicenseRemovalResult = "All Microsoft 365 Licenses removed successfully."
        }
        catch [System.Exception] {
            $LicenseRemovalResult = "Removing Microsoft 365 licenses failed."
            "Failed to remove license: {0}" -f  $_.Exception.Message
        }
    }
}

Disconnect-AzureAD
