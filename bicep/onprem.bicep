targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
var vAzureBgpAsn = 65000

/* ON-PREMISE VIRTUAL NETWORK */
resource resOnPremiseVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'onpremise-vnet'
  location: pRGLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.233.0.0/21'
      ]
    }
    dhcpOptions: {
      dnsServers: [
        '10.233.2.4'
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.233.0.0/26'
        }
      }
      {
        name: 'snet-default'
        properties: {
          addressPrefix: '10.233.1.0/24'
        }
      }
      {
        name: 'snet-dns-inbound'
        properties: {
          addressPrefix: '10.233.2.0/28'
        }
      }
      {
        name: 'snet-dns-outbound'
        properties: {
          addressPrefix: '10.233.2.16/28'
        }
      }
    ]
  }
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

/* PRIVATE ZONE */
resource resOnPremisePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'contoso.internal'
  location: pRGLocation
}

resource resOnPremiseDnsRecord1 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${resOnPremisePrivateDnsZone.name}/onpremise-vm'
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: '10.233.1.4'
      }
    ]
  }
}

resource resOnPremisePrivateZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${resOnPremisePrivateDnsZone.name}/vnet-link'
  properties: {
    registrationEnabled: true
    virtualNetwork: resOnPremiseVnet
  }
}

/* VPN GATEWAY */
resource resOnPremiseVpnGwPip 'Microsoft.Network/publicIPAddresses@2021-08-01' = {
  name: 'onpremise-vpngw-ip'
  location: pRGLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resOnPremiseVpnGw 'Microsoft.Network/virtualNetworkGateways@2021-08-01' = {
  name: 'onpremise-vpngw'
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
            id: resOnPremiseVpnGwPip.id
          }
          subnet: {
            id: resOnPremiseVnet.properties.subnets[0].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

/* VIRTUAL MACHINE */
resource resOnPremNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'onpremise-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resOnPremiseVnet.properties['subnets'][1].id
          }
          privateIPAllocationMethod: 'Dynamic'
        }
      }
    ]
  }
  tags: {
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

resource resOnpremVm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: 'onpremise-vm'
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
        resOnPremNic
      ]
    }
    storageProfile: {
      osDisk: {
        caching: 'ReadWrite'
        osType: 'Linux'
        name: 'onpremise-vm-od01'
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
    environment: 'onprem'
    deployment: 'bicep'
    microhack: 'dns-private-resolver'
  }
}

/* OUTPUTS */
output outOnPremiseVnetId string = resOnPremiseVnet.id
output outOnPremiseVpnGwPip string = resOnPremiseVpnGwPip.properties['ipAddress']
output outOnPremiseVnetAddressSpace string = resOnPremiseVnet.properties['addressSpace'].addressPrefixes[0]
