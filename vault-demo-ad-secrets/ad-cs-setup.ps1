New-AdUser -Name "legacy_admin" -UserPrincipalName "legacy_admin@vault.lab" -SamAccountName "legacy_admin" -AccountPassword (ConvertTo-SecureString "NJUf9suBRK!w" -AsPlainText -Force) -ChangePasswordAtLogon $False -Enabled $True
New-AdUser -Name "sa1"  -UserPrincipalName "sa1@vault.lab" -SamAccountName "sa1" -AccountPassword (ConvertTo-SecureString "NJUf9suBRK!w" -AsPlainText -Force) -ChangePasswordAtLogon $False -Enabled $True
New-AdUser -Name "sa2"  -UserPrincipalName "sa2@vault.lab" -SamAccountName "sa2" -AccountPassword (ConvertTo-SecureString "NJUf9suBRK!w" -AsPlainText -Force) -ChangePasswordAtLogon $False -Enabled $True
Add-ADGroupMember -Identity "Domain Admins" -Members legacy_admin, sa1, sa2

Install-WindowsFeature AD-Certificate -IncludeManagementTools
Install-AdcsCertificationAuthority -CAType EnterpriseRootCA -CACommonName $(hostname) -Confirm:$false
Restart-Computer -Confirm:$false