# Setup
Before running this workspace:
 - Install AD CS Services
 - Configure AD CS Services
 - Create AD accounts for sa1@vault.lab, sa2@vault.lab and legacy_admin@vault.lab

 Commands

 Check out service account:
vault write -force vault-lab-ad/library/dev/check-out

 Check in service account:
vault write -force vault-lab-ad/library/dev/check-in service_account_names=sa1@vault.lab

 Get password for static-role:
vault read vault-lab-ad/static-cred/legacy_admin

 Rotate password for static-role:
vault write -force vault-lab-ad/rotate-role/legacy_admin

