targetScope='subscription'

// Parameters for Resource Group creation
@description('Target resource group')
param resourceGroupName string

@description('Region')
param resourceGroupLocation string = 'westeurope'

// Parameters for calling main module
@description('The name of the function app that you wish to create.')
param appName string = 'testapptjk'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Log Analytics Workspace name')
param laName string = 'DefaultWorkspace-30483fd2-311e-4847-81bf-4fa79f8f8f44-WEU'

@description('Log Analytics Resource Group name')
param laResourceGroup string = 'DefaultResourceGroup-WEU'

@description('Log Analytics Workspace ID')
param workspaceId string = 'ab431c8494a14886aa0576f01ea23b5a'

@description('Custom Table Name (without _CL)')
param customTableName string = 'RunningVMs'

@description('AzureSubscription IDs is a comma separated list')
param azureSubscriptionIDs string = '30483fd2-311e-4847-81bf-4fa79f8f8f44,67aa3a00-7f19-49c3-9c46-5d6d3c508072'


resource FunctionAppRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: resourceGroupName
  location: resourceGroupLocation
}

resource LogAnalyticsRG 'Microsoft.Resources/resourceGroups@2021-01-01' = {
  name: laResourceGroup
  location: resourceGroupLocation
}

module customTable 'customtable.bicep' = {
  name: 'customTable'
  scope: LogAnalyticsRG
  params:{
    laName: laName
    customTableName: customTableName
  }
}

module functionappDeployment 'functionappdeployment.bicep' = {
  name: 'functionappDeployment'
  scope: FunctionAppRG
  params:{
    appName: appName
    storageAccountType: storageAccountType
    location: resourceGroupLocation
    laName: laName
    laResourceGroup: laResourceGroup
    workspaceId: workspaceId
    customTableName: customTableName
    azureSubscriptionIDs: azureSubscriptionIDs
  }
}

output dceURI string = functionappDeployment.outputs.dceURI
output dcrImmutableId string = functionappDeployment.outputs.dcrImmutableId
output functionAppName string = functionappDeployment.outputs.functionAppName
output principalId string = functionappDeployment.outputs.principalId
