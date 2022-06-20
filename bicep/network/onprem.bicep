targetScope = 'resourceGroup'

param pRGLocation string = resourceGroup().location
var vOnPremBgpAsn = 65000

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

  resource resGatewaySubnet 'subnets' existing = {
    name: 'GatewaySubnet'
  }

  resource resDefaultSubnet 'subnets' existing = {
    name: 'snet-default'
  }
}

/* PRIVATE ZONE */
resource resOnPremisePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'contoso.internal'
  location: 'Global'
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
  location: 'Global'
  properties: {
    registrationEnabled: true
    virtualNetwork: {
      id: resOnPremiseVnet.id
    }
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
      asn: vOnPremBgpAsn
    }
    ipConfigurations: [
      {
        name: 'vnetGatewayIpConfig'
        properties: {
          publicIPAddress: {
            id: resOnPremiseVpnGwPip.id
          }
          subnet: {
            id: resOnPremiseVnet::resGatewaySubnet.id
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
resource resDiagnosticStorage 'Microsoft.Storage/storageAccounts@2021-09-01' = {
  name: 'onpremisediag190622'
  location: pRGLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

resource resOnPremNic 'Microsoft.Network/networkInterfaces@2021-08-01' = {
  name: 'onpremise-vm-ni01'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig1'
        properties: {
          subnet: {
            id: resOnPremiseVnet::resDefaultSubnet.id
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: resDiagnosticStorage.properties['primaryEndpoints'].blob
      }
    }
    osProfile: {
      computerName: 'onpremise-vm'
      adminUsername: 'adminuser'
      adminPassword: 'Thqnhat@199'
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resOnPremNic.id
        }
      ]
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
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
      vmSize: 'Standard_D2as_v5'
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
