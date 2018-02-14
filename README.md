# cgw
connectivity gateway

## Configuration
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
  

