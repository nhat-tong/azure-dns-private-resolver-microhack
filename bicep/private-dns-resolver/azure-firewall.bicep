targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location

resource resAzureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: 'hub-vnet/AzureFirewallSubnet'
}

resource resFirewallPIP 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'azfw-pip'
  location: pRGLocation
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource resAzureFirewallDnsProxy 'Microsoft.Network/azureFirewalls@2021-08-01' = {
  name: 'myazfw'
  location: pRGLocation
  zones: []
  properties: {
    sku: {
      tier: 'Standard'
    }
    ipConfigurations: [
      {
        name: 'azfw-pip'
        properties: {
          publicIPAddress: {
            id: resFirewallPIP.id
          }
          subnet: {
            id: resAzureFirewallSubnet.id
          }
        }
      }
    ]
  }
}

resource resLogWorkspace 'Microsoft.OperationalInsights/workspaces@2021-12-01-preview' = {
  name: 'azure-log-workspace'
  location: pRGLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: 1
    }
    features: {}
  }
}

resource resFirewallDiagnosticSetting 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: 'azfw-diag2workspace'
  scope: resAzureFirewallDnsProxy
  properties: {
    workspaceId: resLogWorkspace.id
    logs: [
      {
        category: 'AzureFirewallApplicationRule'
        enabled: true
      }
      {
        category: 'AzureFirewallNetworkRule'
        enabled: true
      }
      {
        category: 'AzureFirewallDnsProxy'
        enabled: true
      }
    ]
  }
}
