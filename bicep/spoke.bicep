targetScope = 'resourceGroup'

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
}

resource resHubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' existing = {
  name: 'hub-vnet'
}


/* VNET PEERING */
resource resPeeringSpoke2Hub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${resSpokeVnet.name}/PEERING_SPOKE01_TO_HUB'
  properties: {
    remoteVirtualNetwork: resHubVnet
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: false
    useRemoteGateways: true
  }
}

resource resPeeringHub2Spoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2021-08-01' = {
  name: '${resHubVnet.name}/PEERING_HUB_TO_SPOKE01'
  properties: {
    remoteVirtualNetwork: resSpokeVnet
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: true
    useRemoteGateways: false
  }
}

/* VIRTUAL MACHINE */
resource resSpokeNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'spoke01-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resSpokeVnet.properties['subnets'][0].id
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
    osProfile: {
      adminUsername: 'adminuser'
      adminPassword: 'Thqnhat@1990'
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        resSpokeNic
      ]
    }
    storageProfile: {
      osDisk: {
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
      vmSize: 'Standard_DS1_v2'
    }
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

/* PRIVATE ENDPOINT */
resource resPostgresSql 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: 'spoke01-pgsql'
  location: pRGLocation
  sku: {
    name: 'GP_Gen5_2'
  }
  properties: {
    createMode: 'Default'
    administratorLogin: 'adminuser'
    administratorLoginPassword: 'Thqnhat@1990'
    storageProfile: {
      storageMB: 51200
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
      storageAutogrow: 'Enabled'
    }
    version: '11'
    sslEnforcement: 'Enabled'
    minimalTlsVersion: 'TLS1_2'
  }
}

resource resPostgresPrivateEndpoint 'Microsoft.Network/privateEndpoints@2021-08-01' = {
  name: 'spoke01-pgsql-endpoint'
  location: pRGLocation
  properties: {
    subnet: {
      id: resSpokeVnet.properties['subnets'][0].id
    }
    privateLinkServiceConnections: [
      {
        name: 'spoke01-pgsql-privateserviceconnection'
        id: resPostgresSql.id
        properties: {
          groupIds: [
            
          ]
        }
      }
    ]
  }
}
