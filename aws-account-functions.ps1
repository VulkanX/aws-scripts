# Powershell testing

function Export-AWSAccountProfiles {
    param (
        [Parameter()][string]$profilename = $null,
        [Parameter()][string]$accessRole = $null,
        [Parameter()][string]$region = "us-east-1",
        [Parameter()][string]$role = "AdministratorAccess"
    )
    $awsAccounts = $null
    try {
        
        if ($profilename -eq $null) {
            $awsAccounts = aws organizations list-accounts --query 'Accounts[*].[Id, Name]' --output text
        }
        else {
            $awsAccounts = aws organizations list-accounts --profile $accessRole --query 'Accounts[*].[Id, Name]' --output text
        }
    }
    catch {
        write-host "Error: Unable to get AWS Account Information"
        return
    }

    foreach ($awsAccount in $awsAccounts) {
        $account = $awsAccount.split("`t")
        $accountId = $account[0]
        write-host "[profile $accountId]"
        write-host "sso_session = $profilename"
        write-host "sso_account_id = $accountId"
        write-host "sso_role_name = $role"
        write-host ""
    }
}

function Get-AWSContactInfo {
    param (
        [Parameter()][string]$profileName  = $null
    )
    
    # Get AWS Account Information from aws account and display it as a powershell object
    $awsAccounts = $null
    try {
        
        if ($profileName -eq $null) {
            $awsAccounts = aws organizations list-accounts --query 'Accounts[*].[Id, Name]' --output text
        }
        else {
            $awsAccounts = aws organizations list-accounts --profile $profileName --query 'Accounts[*].[Id, Name]' --output text
        }
    }
    catch {
        write-host "Error: Unable to get AWS Account Information"
        return
    }

    # Generate custom object to store account information
    $awsAccountInfo = @()

    foreach ($awsAccount in $awsAccounts) {
        $account = $awsAccount.split("`t")
        $accountId = $account[0]
        $accountName = $account[1]
        $awsSecurityContact = $null
        $awsBillingContact = $null
        $awsOperationsContact = $null

        # Get Alternate contact information for Security, Billing, and opeartions
        try {
            $awsSecurityInfo = (aws account get-alternate-contact --alternate-contact-type SECURITY --profile $accountId --query 'AlternateContact.[EmailAddress, Name, PhoneNumber, Title]' --output text).Split("`t")  2>$null
            $awsSecurityContact = $awsSecurityInfo[3] + " (" + $awsSecurityInfo[0] + ")"
        }
        catch {
            $awsSecurityContact = $null    
        }

        try {
            $awsBillingInfo = (aws account get-alternate-contact --alternate-contact-type BILLING --profile $accountId --query 'AlternateContact.[EmailAddress, Name, PhoneNumber, Title]' --output text).Split("`t") 2>$null
            $awsBillingContact = $awsBillingInfo[3] + " (" + $awsBillingInfo[0] + ")"
        }
        catch {
            $awsBillingContact = $null    
        }

        try {
            $awsOperationsInfo = (aws account get-alternate-contact --alternate-contact-type OPERATIONS --profile $accountId --query 'AlternateContact.[EmailAddress, Name, PhoneNumber, Title]' --output text).Split("`t") 2>$null
            $awsOperationsContact = $awsOperationsInfo[3] + " (" + $awsOperationsInfo[0] + ")"
        }
        catch {
            $awsOperationsContact = $null
        }

        

        # Store Account Details in custom object
        $awsAccountInfo += [PSCustomObject]@{
            AccountId = $accountId
            AccountName = $accountName
            SecurityContact = $awsSecurityContact
            BillingContact = $awsBillingContact
            OperationsContact = $awsOperationsContact
        }
    }

    return $awsAccountInfo

}

# Example usage

### With Profile in AWS Configure
# Get-AWSContactInfo -profile my-profile | ft -AutoSize

### Without Profile in AWS Configure
# Get-AWSContactInfo | ft -autosize

### 
# Get-AWSAccountProfiles -profilename <AWS CONFIGURE SSO PROFILE> -accessRole <AWS CONFIGURE ALIAS> -role AWSAdministratorAccess
