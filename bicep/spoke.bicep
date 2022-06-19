targetScope = 'resourceGroup'

var privateEndpointName = 'blob-private-endpoint'
param pRGLocation string = resourceGroup().location

/* VIRTUAL NETWORK */
resource resSpokeVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'spoke01-vnet'
  location: pRGLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.221.8.0/24'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '10.221.2.4'
      ]
    }
    subnets: [
      {
        name: 'snet-default'
        properties: {
          addressPrefix: '10.221.8.0/24'
          privateEndpointNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }

  resource resDefaultSnet 'subnets' existing = {
    name: 'snet-default'
  }
}

resource resHubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'hub-vnet'
  scope: resourceGroup('hub02-rg')
}

module modulePeeringSpoke2Hub 'vnet_peering.bicep' = {
  name: 'module-peering-spoke2hub'
  scope: resourceGroup()
  params: {
    vnetPeeringName: 'PEERING_SPOKE01_TO_HUB'
    localVnetName: resSpokeVnet.name
    remoteVnetName: resHubVnet.name
    vnetResourceGroupName: 'hub02-rg'
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}

module modulePeeringHub2Spoke 'vnet_peering.bicep' = {
  name: 'module-peering-hub2spoke'
  scope: resourceGroup('hub02-rg')
  params: {
    vnetPeeringName: 'PEERING_HUB_TO_SPOKE01'
    localVnetName: resHubVnet.name
    remoteVnetName: resSpokeVnet.name
    vnetResourceGroupName: 'spoke02-rg'
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

/* VIRTUAL MACHINE */
resource resDiagStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'spokediag190622'
  location: pRGLocation 
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource resSpokeNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'spoke01-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resSpokeVnet::resDefaultSnet.id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resSpokeVm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'spoke01-vm'
  location: pRGLocation
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: resDiagStorage.properties['primaryEndpoints'].blob
      }
    }
    osProfile: {
      computerName: 'spoke01-vm'
      adminUsername: 'adminuser'
      adminPassword: 'Thqnhat@199'
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resSpokeNic.id
        }
      ]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        caching: 'ReadWrite'
        osType: 'Linux'
        name: 'hub-vm-od01'
      }
      imageReference: {
        publisher: 'canonical'
        offer: 'UbuntuServer'
        sku: '18_04-lts-gen2'
        version: 'latest'
      }
    }
    hardwareProfile: {
      vmSize: 'Standard_D2as_v5'
    }
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

/* PRIVATE ENDPOINT */
// resource resPostgresSql 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
//   name: 'spoke01-pgsql'
//   location: pRGLocation
//   sku: {
//     name: 'GP_Gen5_2'
//   }
//   properties: {
//     createMode: 'Default'
//     administratorLogin: 'adminuser'
//     administratorLoginPassword: 'Thqnhat@1990'
//     storageProfile: {
//       storageMB: 51200
//       backupRetentionDays: 7
//       geoRedundantBackup: 'Disabled'
//       storageAutogrow: 'Enabled'
//     }
//     version: '11'
//     sslEnforcement: 'Enabled'
//     minimalTlsVersion: 'TLS1_2'
//   }
// }
resource resPrivateStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'privatestorage190622'
  location: pRGLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource resBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: privateEndpointName
  location: pRGLocation
  properties: {
    subnet: {
      id: resSpokeVnet::resDefaultSnet.id
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-serviceconnection'
        properties: {
          privateLinkServiceId: resPrivateStorage.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource resBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' existing  = {
  name: 'privatelink.blob.core.windows.net'
  scope: resourceGroup('hub02-rg')
}

resource resPrivateZoneDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-08-01' = {
  name: '${privateEndpointName}/dnsgroupname'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privateDnsZoneConfig'
        properties: {
          privateDnsZoneId: resBlobPrivateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    resBlobPrivateEndpoint
  ]
}
