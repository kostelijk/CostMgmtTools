@description('Log Analytics Workspace name')
param laName string = 'DefaultWorkspace-30483fd2-311e-4847-81bf-4fa79f8f8f44-WEU'

@description('Custom Table Name (without _CL)')
param customTableName string = 'RunningVMs'

resource runningVMTable 'Microsoft.OperationalInsights/workspaces/tables@2021-12-01-preview' = {
  name: '${laName}/${customTableName}_CL'
  properties: {
    plan: 'Analytics'
    schema: {
      name: '${customTableName}_CL'
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
}
