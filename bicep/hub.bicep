targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
var vAzureBgpAsn = 64000

/* VIRTUAL NETWORK */
resource resHubVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'hub-vnet'
  location: pRGLocation
  properties: {
    addressSpace: {
       addressPrefixes: [
         '10.221.0.0/21'
       ]
    }
    dhcpOptions: {
       dnsServers: [
         '10.221.2.4'
       ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.221.0.0/26'
        }
      }
      {
        name: 'snet-default'
        properties: {
          addressPrefix: '10.221.1.0/24'
        }
      }
      {
        name: 'snet-dns-inbound'
        properties: {
          addressPrefix: '10.221.2.0/28'
        }
      }
      {
        name: 'snet-dns-outbound'
        properties: {
          addressPrefix: '10.221.2.16/28'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '10.221.3.0/26'
        }
      }
    ]
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }

  resource resGatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }

  resource resDefaultSubnet 'subnets' existing = {
    name: 'snet-default'
  }
}

/* PRIVATE ZONE */
resource resAzureConsotoPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'contoso.azure'
  location: 'Global'
}

resource resBlobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.blob.core.windows.net'
  location: 'Global'
}

resource resAzureDnsRecord1 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${resAzureConsotoPrivateDnsZone.name}/hub-vm'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.221.1.4'
      }
    ]
  }
}

resource resAzureDnsRecord2 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${resAzureConsotoPrivateDnsZone.name}/spoke01-vm'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.221.8.4'
      }
    ]
  }
}


resource resAzurePrivateZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${resAzureConsotoPrivateDnsZone.name}/vnet-link'
  location: 'Global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

resource resBlobPrivateZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${resBlobPrivateDnsZone.name}/vnet-link'
  location: 'Global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: resHubVnet.id
    }
  }
}

/* VPN GATEWAY */
resource resHubVpnGwPip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'hub-vpngw-ip'
  location: pRGLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    environment: 'cloud'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resHubVpnGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' = {
  name: 'hub-vpngw2'
  location: pRGLocation
  properties: {
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    activeActive: false
    enableBgp: true
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
    bgpSettings: {
      asn: vAzureBgpAsn
    }
    ipConfigurations: [
      {
        name: 'vnetGatewayIpConfig'
        properties: {
          publicIPAddress: {
            id: resHubVpnGwPip.id
          }
          subnet: {
            id: resHubVnet::resGatewaySubnet.id
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

/* VIRTUAL MACHINE */
resource resStorageDiagnostic 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'hubdiag190622'
  location: pRGLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource resHubNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'hub-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resHubVnet::resDefaultSubnet.id
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

resource resHubVm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'hub-vm'
  location: pRGLocation
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: resStorageDiagnostic.properties['primaryEndpoints'].blob
      }
    }
    osProfile: {
      computerName: 'hub-vm'
      adminUsername: 'adminuser'
      adminPassword: 'Thqnhat@199'
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resHubNic.id
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

output outHubVnetId string = resHubVnet.id
output outHubVpnGwPip string = resHubVpnGwPip.properties['ipAddress']
output outHubVnetAddressSpace string = resHubVnet.properties['addressSpace'].addressPrefixes[0]
