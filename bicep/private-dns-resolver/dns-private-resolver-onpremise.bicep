targetScope = 'resourceGroup'

/* PARAMETERS */
param pRGLocation string = resourceGroup().location
param pDnsResolverForwardingRules array = [
  {
    name: 'fw-contoso-azure'
    domainName: 'contoso.azure.'
    targetDnsServers: [
      {
        ipAddress: '10.221.2.4'
        port: 53
      }
    ]
    state: 'Enabled'
  }
  {
    name: 'fw-private-endpoint'
    domainName: 'privatelink.blob.core.windows.net.'
    targetDnsServers: [
      {
        ipAddress: '10.221.2.4'
        port: 53
      }
    ]
    state: 'Enabled'
  }
]

resource resOnPremVnet 'Microsoft.Network/virtualNetworks@2021-05-01' existing = {
  name: 'onpremise-vnet'
}

resource resSubnetInbound 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${resOnPremVnet.name}/snet-dns-inbound'
}

resource resSubnetOutbound 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' existing = {
  name: '${resOnPremVnet.name}/snet-dns-outbound'
}

resource resDnsResolver 'Microsoft.Network/dnsResolvers@2020-04-01-preview' = {
  name: 'private-dns-resolver'
  location: pRGLocation
  properties: {
    virtualNetwork: {
      id: resOnPremVnet.id
    }
  }
}

resource resDnsResolverInboundEndpoint 'Microsoft.Network/dnsResolvers/inboundEndpoints@2020-04-01-preview' = {
  name: '${resDnsResolver.name}/inbound-ep'
  location: pRGLocation
  properties: {
    ipConfigurations: [
      {
        privateIpAllocationMethod: 'Dynamic'
        subnet: {
          id: resSubnetInbound.id
        }
      }
    ]
  }
}

resource resDnsResolverOutboundEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2020-04-01-preview' = {
  name: '${resDnsResolver.name}/outbound-ep'
  location: pRGLocation
  properties: {
    subnet: {
      id: resSubnetOutbound.id
    }
  }
}

resource resDnsResolverForwardingRuleSet 'Microsoft.Network/dnsForwardingRulesets@2020-04-01-preview' = {
  name: 'forwardingruleset-default'
  location: pRGLocation
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: resDnsResolverOutboundEndpoint.id
      }
    ]
  }
}

resource resDnsResolverVnetLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2020-04-01-preview' = {
  name: '${resDnsResolverForwardingRuleSet.name}/ruleSetVnetLink'
  properties: {
    virtualNetwork: {
      id: resOnPremVnet.id
    }
  }
}

resource resDnsResolverForwardingRules  'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2020-04-01-preview' = [for rule in pDnsResolverForwardingRules: {
  name: '${resDnsResolverForwardingRuleSet.name}/${rule.name}'
  properties: {
    domainName: rule.domainName
    targetDnsServers: rule.targetDnsServers
    forwardingRuleState: rule.state
  }
}]
