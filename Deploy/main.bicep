@description('The name of the function app that you wish to create.')
param appName string = 'fnapp${uniqueString(resourceGroup().id)}'

@description('Storage Account type')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Log Analytics Workspace name')
param laName string = 'DefaultWorkspace-30483fd2-311e-4847-81bf-4fa79f8f8f44-WEU'

@description('Log Analytics Resource Group name')
param laResourceGroup string = 'DefaultResourceGroup-WEU'

@description('Log Analytics Workspace ID')
param workspaceId string = 'ab431c8494a14886aa0576f01ea23b5a'

@description('Custom Table Name (without _CL)')
param customTableName string = 'RunningVMs'

var functionAppName = appName
var hostingPlanName = appName
var applicationInsightsName = appName
var storageAccountName = '${uniqueString(resourceGroup().id)}azfunctions'
var runtime = 'powershell'
var functionWorkerRuntime = runtime
var dceName = 'LogRunningVMs'
var dcrName = 'CollectRunningVMs'
var customTableName_CL = 'Custom-${customTableName}_CL'
var streamDeclarations = { 'Custom-${customTableName}_CL': {
                            columns: [
                              {
                                  name: 'TimeGenerated'
                                  type: 'datetime'
                              }
                              {
                                  name: 'Application'
                                  type: 'string'
                              }
                              {
                                  name: 'VmSize'
                                  type: 'string'
                              }
                              {
                                  name: 'Value'
                                  type: 'int'
                              }
                            ]
                          }
                        }
var workspaceResourceId = resourceId(laResourceGroup,'Microsoft.OperationalInsights/workspaces',laName)

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'Storage'
}

resource hostingPlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
  }
  properties: {}
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: hostingPlan.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~10'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: applicationInsights.properties.InstrumentationKey
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: functionWorkerRuntime
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME_VERSION'
          value: '~7'
        }
        {
          name: 'dcrImmutalbeId'
          value: dataCollectionRule.properties.immutableId
        }
        {
          name: 'dceURI'
          value: dataCollectionEndpoint.properties.logsIngestion.endpoint
        }
      ]
      ftpsState: 'FtpsOnly'
      minTlsVersion: '1.2'
    }
    httpsOnly: true
  }
}

resource functionAppConfig 'Microsoft.Web/sites/config@2022-03-01' = {
  name: '${appName}/web'
  dependsOn:[
    functionApp
  ]
  properties:{
    use32BitWorkerProcess: false
    powerShellVersion: '7.2'
  }
}

resource applicationInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: applicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2021-09-01-preview' = {
  name: dceName
  location: location
  properties: {
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
}

resource dataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-09-01-preview' = {
  name: dcrName
  location: location
  properties:{
    dataCollectionEndpointId: dataCollectionEndpoint.id
    streamDeclarations: streamDeclarations
    dataSources: {
      
    }
    destinations:{
      logAnalytics: [
        {
          workspaceResourceId: workspaceResourceId
          name: workspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          customTableName_CL
        ]
        destinations:[
          workspaceId
        ]
        transformKql: 'source'
        outputStream: customTableName_CL
      }
    ]
  }
}

output dceURI string = dataCollectionEndpoint.properties.logsIngestion.endpoint
output dcrImmutableId string = dataCollectionRule.properties.immutableId
output functionAppName string = appName
