# CostMgmtTools

## Log-RunningVM
This Function app reports on how many VM's per VmSize currently are running. This information is logged to a Log Analytics workspace. This is especially usefull for machines that are dynamically switched on and of. The logging could help in deciding how to purchase an Azure Saving plan. 

Information on how to setup Log Analytics, a Data Collection Endpoint and a Data Collection rule can be found in [Tutorial: Send data to Azure Monitor Logs using REST API (Azure portal)](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal)

The Function App must be configured with a managed identity. 
The managed identity should have read permissions to the subscritpions in scope to be able to collect VM powerstate information. (This is taken care off by the deploy pipeline)
The Function App Application Settings should contain these additional Application Settings:
- **AzureSubscription_IDs.** A comma seperated list of subscription id's 
- **DceURI.** The URI which is configured during the configuration of the Data Collection Endpoint. [Configure Application](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#configure-application) 
- **DcrImmutableId.** [Collect information from DCR](https://learn.microsoft.com/en-us/azure/azure-monitor/logs/tutorial-logs-ingestion-portal#collect-information-from-dcr)

## Workflow identity federation
The solution uses [Workflow identity federation](https://learn.microsoft.com/en-us/azure/active-directory/develop/workload-identity-federation) to run the GitHub Actions. Permissions to the app registration being used were set on management group level. This way the pipeline can set read permissions for the function app on every subscription in scope (needed to get all the running VMs). Example: [Set up environment](https://learn.microsoft.com/en-us/training/modules/test-bicep-code-using-github-actions/4-exercise-set-up-environment?pivots=powershell)

Example script to configure Workflow identity federation:
```powershell
#Set Variables
$githubOrganizationName = '<GithubHandle>'
$githubRepositoryName = '<RepoName>'
$mgmtGroupId = (Get-AzManagementGroup|Where-Object {$_.DisplayName -eq "Tenant Root Group"}).Id

#Create workload identity.
$applicationRegistration = New-AzADApplication -DisplayName $githubRepositoryName
New-AzADAppFederatedCredential `
   -Name "$githubRepositoryName-app" `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):ref:refs/heads/main" # Main branch
   #-Subject "repo:$($githubOrganizationName)/$($githubRepositoryName):environment:Website" # When working with Github Environments in public repo's


New-AzADServicePrincipal -AppId $($applicationRegistration.AppId)
New-AzRoleAssignment `
   -ApplicationId $($applicationRegistration.AppId) `
   -RoleDefinitionName Owner `
   -Scope $mgmtGroupId

#Prepare GitHub secrets. The values shown in the output should be created as GitHub Secrets 
$azureContext = Get-AzContext
Write-Host "AZURE_CLIENT_ID: $($applicationRegistration.AppId)"
Write-Host "AZURE_TENANT_ID: $($azureContext.Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $($azureContext.Subscription.Id)"
```
