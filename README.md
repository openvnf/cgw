# cgw
connectivity gateway

<!-- toc -->

* [IPSEC](#ipsec)
  * [Manual Strongswan configuration](#manual-strongswan-configuration)
* [iptables](#iptables)
* [BGP](#bgp)
  * [BIRD Internet Routing Daemon](#bird-internet-routing-daemon)
* [VXLAN](#vxlan)
  * [manual VXLAN setup](#manual-vxlan-setup)
  * [VXLAN-Controller configuration](#vxlan-controller-configuration)
* [GRE](#gre)
* [Monitoring](#monitoring)
  * [Configure targets](#configure-targets)
  * [disable ping-prober](#disable-ping-prober)
* [Utilities](#utilities)
  * [debug container](#debug-container)
  * [init script](#init-script)

<!-- tocstop -->

## IPSEC

### Manual Strongswan configuration

To use a manual configuration of Strongswan instead of using parameters, for example for multi-SA configurations,
set the following parameters:

```yaml
ipsec:
  manualConfig: true # default is false
  strongswan:
    ipsecConfig:
      ipsec.<myconnectionname>.conf: |
        <add your ipsec config here>
    ipsecSecrets:
      ipsec.<myconnectionname>.secrets: |
        <add your ipsec secret here>
```

The `ipsec.<myconnectionname>.conf` has to follow the [Strongswan documentation](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf).

The `ipsec.<myconnectionname>.secrets` also have to follow the [Strongswan secrets documentation](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecSecrets).
They will also automatically be base64 encoded into a Kubernetes Secret.

You can repeat the configuration for multiple connections.

NOTE: If the manual configuration is used, the ping-prober must be disabled!! (see [ping-prober](#disable_ping-prober))

#### disable setting of routes

If Strongswan shall not install routes into its routing table, you have to set the value `ipsec.vti_key: true`.

### setting interfaces

To set the interfaces Strongswan shall bind on, set `ipsec.interfaces` with a comma seperated list of interfaces.

For example:

```yaml
ipsec:
  interfaces: "eth0,net1"
```

## iptables

This deployment might use pods, which have interfaces publicly connected to the internet.
Therefore the pods have to be secured using a firewall.

By default the corresponding `iptables` container is disabled as well as the rule files.

To secure your CGW you have to add rules to in the following part of configuration:

```yaml
iptables:
  enabled: true # disable is false
  ipv4Rules: |
    *filter

    # Block all traffic silently as default policy
    # just use this one with care
    #-P INPUT DROP
    #-P FORWARD DROP
    #-P OUTPUT DROP

    # Allows all loopback (lo0) traffic and drop all traffic to 127/8 that doesn't use lo0
    -A INPUT -i lo0 -j ACCEPT
    -A INPUT ! -i lo0 -d 127.0.0.0/8 -j REJECT
    
    ######   ADD YOUR RULES TO EXTEND TRAFFIC HERE ######
    
    COMMIT
  ipv6Rules: |
    *filter

    # Block all traffic silently as default policy
    # just use this one with care
    #-P INPUT DROP
    #-P FORWARD DROP
    #-P OUTPUT DROP

    # Allows all loopback (lo0) traffic and drop all traffic to ::1 that doesn't use lo0
    -A INPUT -i lo0 -j ACCEPT
    -A INPUT ! -i lo0 -d ::1 -j REJECT
    
    ######   ADD YOUR RULES TO EXTEND TRAFFIC HERE ######

    COMMIT
```

The configuration parameters `ipv4Rules` and `ipv6Rules` will be used as a rule file for `iptables-restore` literally.

## BGP

### BIRD Internet Routing Daemon

To use BGP in the CGW deployment, you can enable BIRD as follows:

```yaml
bird:
  enabled: true # default is false
  configuration:
    bird: |
      < add the bird IPv4 configuration here>
    bird6: |
      < add the bird6 IPv6 configuration here>
```

At the moment, you have to configure BIRD manually following the [BIRD documentation](http://bird.network.cz/?get_doc&v=16&f=bird-3.html).

The version used is `1.6` which differs in its configuration from version `2.0`.


## VXLAN

There are two different ways available of connecting this service with another container.

The first one is the manual way, where the partners have to be configured with values.
The second one is using the *vxlan-controller* and the vxlans can be configured using annotations.

### manual VXLAN setup

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

### VXLAN-Controller configuration

To use the *vxlan-controller* add the following section to the configuration:

```yaml
vxlanController:
  enabled: true
  # The following two values are used to set the key names for the key names
  # and can be infrastructure specific:
  # annotationKey: vxlan.travelping.com/networks
  # metadataKey: vxlan.travelping.com
  names: "vxeth0, vxeth1"
  ip:
  - interface: vxeth1
    addr: "192.0.2.1/24"
    type: ip
  - interface: bridge0
    type: bridge
    bind:
      - gre9
      - vxeth0
  - interface: gre9
    type: interface
    action: up
  staticRoutes:
  - "203.0.113.15 via 192.0.2.1" 
  - "203.0.113.16 via 192.0.2.1"
```

The networks have to be configured already by the controller and have to be provided as a comma seperated
list (`vxlanController.names`).

The `vxlanController.ip` section can be provided by a list of configurations.
Three types are available. One for assigning a static IP address to an interface, the second
to add a bridge and bind interfaces to them and the third to set interfaces to state `up` or `down`.

Additionally `vxlanController.staticRoutes` can be configured with a list of static routes as strings
to be configured in the default routing table of the pod.


## GRE

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
  

## Monitoring

The monitoring component of *CGW* supports ICMP echoes to defined endpoints and exposes it via an
http endpoint in prometheus format.

By default the component will send pings to the address stated in `ipsec.remote_ping_endpoint` from the address
configured in `ipsec.local_ping_endpoint`.

A service will be exposed and will be scraped automatically by common configured prometheus instances.

By default the service will be called `<release name>-cgw` and the metrics will be available at
`http://<release name>-cgw:9427/metrics`

### Configure targets

To configure additional targets or source addresses, you have to configure the values as follows:

```yaml
pingExporter:
  targets:
    - sourceV4: 192.0.2.1          # Source address of ICMP requests
      sourceV6: "2001:0DB8:1::1"   # Source address of ICMP requests
      pingInterval: 5s             # interval for ICMP requests
      pingTimeout: 4s              # timeout for ICMP requests
      pingTargets:                 # list of ICMP targets
        - 192.0.2.10
        - 198.51.100.1
    - sourceV4: 192.0.2.2
      sourceV6: "2001:0DB8:2::2"
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - 203.0.113.1
        - "2001:0DB8:2::10"
```
All parameters are required!

When targets are set in this way, the usage of `ipsec.remote_ping_endpoint` and `ipsec.local_ping_endpoint` will
be automatically disabled.

### <a name="disable_ping-prober"></a>disable ping-prober

If *ping-exporter* is configured (see above) the ping-prober can be disabled.
If the manual IPSEC configuration is used, the ping-prober MUST be disabled.

Disable the ping-prober:

```yaml
pingProber:
  enabled: false
```

## Utilities

### debug container

By default a debug container with networking tools will be created.

If this is not desired, disable it as follows:

```yaml
debug:
  enabled: false
```

### init script

To run initialization steps, which are outside of the provided configuration parameters for standard models, you can provide a shellscript to run in a special init container with `NET_ADMIN` priviledges.

To do so, provide the following parameters:

```yaml
initScript:
  enabled: true # default is false
  env:
    # Add environmental variables here
    GREETING: "Hello World"
  script: |
    set -e
    echo "This runs my magic shell script"
    echo "also multi line"
    echo $GREETING
```
