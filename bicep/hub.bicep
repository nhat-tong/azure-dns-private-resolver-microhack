targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
var vOnPremiseBgpAsn = 64000

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
}

/* PRIVATE ZONE */
resource resAzureConsotoPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'contoso.azure'
  location: pRGLocation
}

resource resPostgresPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.postgres.database.azure.com'
  location: pRGLocation
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
  location: pRGLocation
  properties: {
    registrationEnabled: true
    virtualNetwork: resHubVnet
  }
}

resource resPostgresPrivateZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${resPostgresPrivateDnsZone.name}/postgres-link'
  location: pRGLocation
  properties: {
    virtualNetwork: resHubVnet
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
  name: 'hub-vpngw'
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
      asn: vOnPremiseBgpAsn
    }
    ipConfigurations: [
      {
        name: 'vnetGatewayIpConfig'
        properties: {
          publicIPAddress: {
            id: resHubVpnGwPip.id
          }
          subnet: {
            id: resHubVnet.properties.subnets[0].id
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
resource resHubNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'hub-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resHubVnet.properties['subnets'][1].id
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
    osProfile: {
      adminUsername: 'adminuser'
      adminPassword: 'Thqnhat@1990'
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        resHubNic
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

output outHubVnetId string = resHubVnet.id
output outHubVpnGwPip string = resHubVpnGwPip.properties['ipAddress']
output outHubVnetAddressSpace string = resHubVnet.properties['addressSpace'].addressPrefixes[0]
