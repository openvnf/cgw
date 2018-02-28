# cgw
connectivity gateway

## Configuration

### VTI

To disable the usage of VTI and therefor use policy based routing set the key to false:

```yaml
ipsec:
  vti_key: false
```

### IPSEC
#### PSK

To the pre-shared key for the connection, you can either set it directly in you values:

```yaml
ipsec:
  psk: 
    value: "<my-very-secret-psk>"
```

This is though discouraged, because the secrets might be commited to your repository.

Instead, also a kubernetes secret can be used as following:

```yaml
ipsec:
  psk:
    secret:
      name: <name of the secret>
      key: <name of the key in the secret>
```

### Calico

In a setup, where the calico network should be connected to another side transparently with this CGW.
If the following options are set, the route will be statically configured on all nodes but the
excluded one.

The gateway address is the internal calico IP address of the node executing the CGW.

ATTENTION: Because of changes on your infrastructure, use this option with care!

The following is a sample configuration for usage with Calico.

```yaml
calcioSetup:
  enabled: true
  # exclude hosts with mathching labels
  excludeHost:
    key: ipsec-cp
    value: "true"
  # interface to use on all nodes for routing
  interface: tunl0
  # IP address of the gateway
  gateway: 192.0.2.1
```

In a scenario on AWS, the VPC network will not provide all Layer 2 functions and will make custom routing at least cumbersome.
Therefore with Calico the internal overlay network will be used (`tunl0`).

To use a host as the *IPSEC Gateway* for the cluster it is also advised to run in the host network namespace and pin to a certain host. This will not provide HA, but this is also not in the scope of this project right now.

As an example the following parameter could be used for host-pinning and host networking:

```yaml
ipsec:
  vti_key: false
  setDefaultTable: false
  hostNetworking: true
  
nodeSelector:
  ipsec-cp: "true"
  
calcioSetup:
  enabled: true
  excludeHost:
    key: ipsec-cp
    value: "true"
  interface: tunl0
  gateway: 192.0.2.1
```


### VXLAN

VXLAN endpoints inside the CGW can be created by adding a configuration under the `vxlan` key.

For example:

```yaml
vxlan:
  enabled: true
  connectors:
    - name: conn1
      peer: <ip or fqdn of peer>
      bridge: true
      id: 42
      ipaddr: <ip address added to the created interface>
      # mandatory when bridge: true
      # if multiple interfaces shall be bridged,
      # add them as a space seperated list
      bridged_ifaces: eth1
      # bridged_ifaces: "eth1 eth2 net0"
      bridge_name: <name of bridge> # optional: defaults to br0      
```

Multiple interfaces can be added by adding more entries to the list of connectors.
`enabled` has to be explicitly set.


### GRE

A GRE or GRETAP interface can be added for tunneling of IP or Ethernet traffic respectively.

For example:

```yaml
gre:
  enabled: true
  remoteip: <ip of remote host>
  localip: <local ip>
  # It is recommended to use a name different than `gre0`.
  # This might already have be added by loading a kernel module
  name: <name of the interface to be created>
  # if Ethernet traffic shall be tunneled,
  # a GRETAP interface has to be used instead of a GRE interface
  gretap: <true | false> 
```
  

