targetScope = 'resourceGroup'

/* PARAMETERS */
param pRGLocation string = resourceGroup().location
param pAddressPrefixes array = [ '10.233.0.0/21' ]
param pDnsServers array = [ '10.233.2.4' ]
param pOnpremSubnets array = [
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
param pOnPremBgpAsn int = 65000
param pAdminUsername string = ''
param pAdminPassword string = ''
param pVmOnPrem object = {
  name: 'onpremise-vm'
  publisher: 'canonical'
  offer: 'UbuntuServer'
  sku: '18_04-lts-gen2'
  version: 'latest'
  vmSize: 'Standard_D2as_v5'
}
var tags = {
  environment: 'onprem'
  deployment: 'bicep'
  microhack: 'dns-private-resolver'
}

/* ON-PREMISE VIRTUAL NETWORK */
resource resOnPremiseVnet 'Microsoft.Network/virtualNetworks@2021-08-01' = {
  name: 'onpremise-vnet'
  location: pRGLocation
  properties: {
    addressSpace: {
      addressPrefixes: pAddressPrefixes
    }
    dhcpOptions: {
      dnsServers: pDnsServers
    }
    subnets: pOnpremSubnets
  }
  tags: tags

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
  tags: tags
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
      asn: pOnPremBgpAsn
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
  tags: tags
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
  name: pVmOnPrem.name
  location: pRGLocation
  properties: {
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: resDiagnosticStorage.properties['primaryEndpoints'].blob
      }
    }
    osProfile: {
      computerName: pVmOnPrem.name
      adminUsername: pAdminUsername
      adminPassword: pAdminPassword
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
        publisher: pVmOnPrem.publisher
        offer: pVmOnPrem.offer
        sku: pVmOnPrem.sku
        version: pVmOnPrem.version
      }
    }
    hardwareProfile: {
      vmSize: pVmOnPrem.vmSize
    }
  }
  tags: tags
}

/* OUTPUTS */
output outOnPremiseVnetId string = resOnPremiseVnet.id
output outOnPremiseVpnGwPip string = resOnPremiseVpnGwPip.properties['ipAddress']
output outOnPremiseVnetAddressSpace string = resOnPremiseVnet.properties['addressSpace'].addressPrefixes[0]
