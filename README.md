# cgw
connectivity gateway

NOTE: features described with [beta] or [alpha] are not considered stable
in the current version and therefore not recommended for production use.

<!-- toc -->

* [General](#general)
  * [upgrade of the helm chart](#upgrade-of-the-helm-chart)
* [Current Documentation](#current-documentation)
* [Additional documents of CGW with specific topics](#additional-documents-of-cgw-with-specific-topics)
* [Old Configuration Documentation](#old-configuration-documentation)
  * [Starting Point](#starting-point)
  * [IPsec](#ipsec)
      * [disable setting of routes](#disable-setting-of-routes)
    * [disable IPsec service](#disable-ipsec-service)
  * [BGP](#bgp)
    * [BIRD Internet Routing Daemon](#bird-internet-routing-daemon)
    * [bird_exporter](#bird_exporter)
  * [VXLAN](#vxlan)
    * [manual VXLAN setup [deprecated]](#manual-vxlan-setup-deprecated)
    * [VXLAN-Controller configuration](#vxlan-controller-configuration)
  * [GRE](#gre)
  * [VRRP](#vrrp)
  * [PCAP [alpha]](#pcap-alpha)
  * [Rclone [alpha]](#rclone-alpha)
  * [Router Advertisement Daemon](#router-advertisement-daemon)
  * [Monitoring](#monitoring)
    * [Configure targets](#configure-targets)
    * [disable ping-prober](#disable-ping-prober)
  * [Pod wide configurations](#pod-wide-configurations)
    * [additional pod annotations](#additional-pod-annotations)
    * [enable IPv6 routing](#enable-ipv6-routing)
    * [Run CGW on exclusive nodes:](#run-cgw-on-exclusive-nodes)
* [Utilities](#utilities)
  * [debug container](#debug-container)

<!-- tocstop -->

## General

see [General Usage](docs/tutorials/general_usage.md) for general installation overview.

### upgrade of the helm chart
When configurations or secrets are changed, the pods will be redeployed automatically.
This will cause a short interruption of the traffic at the moment.

## Current Documentation

The new documentation is split in four different parts.

* [Tutorials](docs/tutorials/README.md)
* [How Tos](docs/how-tos/README.md)
* [Concepts](docs/concepts/README.md)
* [Reference](docs/reference/README.md)

Depending wheter you learn better top down or bottom up, it makes sense to start with *Concepts* or *Tutorials*.

The *How Tos* expect you to have a basic understanding of CGW and its components, as the settings will not be explained in details, when they are not specific to the *How to* itself.

## Additional documents of CGW with specific topics

* [Configuring firewall with iptables](docs/Firewall.md)

## Old Configuration Documentation
### Starting Point

Many people using the `values.yaml` from this Helm chart as a starting point for their own
configuration.
This is in general considered a bad habit, because it contains quite some values, which are
considered implementation detail and should not be changed besides during development of
CGW itself.

Therefore please start with the following [configuration example](examples/values.yaml).

```yaml
debug:
  enabled: true

ipsec:
  enabled: false

vxlanController:
  enabled: false

iptables:
  enabled: false

initScript:
  enabled: false

pingExporter:
  enabled: false

pingProber:
  enabled: false
```

Due to compatibility with recent versions, there are some modules, which are enabled by default.
With the above configration you get a minimal pod with just the debug container enabled.
Please follow the below configuration documentation to enable and configure the necessary
components for your deployment.

### IPsec

NOTE: If the manual configuration is used, the ping-prober must be disabled!! (see [ping-prober](#disable_ping-prober))

##### disable setting of routes

If Strongswan shall not install routes into its routing table, you have to set the value `ipsec.vti_key: true`.
This is strongly advised, when using VTI interfaces and route-based VPN.


#### disable IPsec service

By default a service will be created, which exposes the IPsec ports.
It is advised to disable the service, if a public IP is used inside the pod.

To disable it set the following:

```yaml
ipsec:
  service:
    enabled: false
```

Deprecation: The service will be disabled by default in the future.

### BGP

#### BIRD Internet Routing Daemon

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

Further, the *bird* container is configured to log to standard out, but if you
want to have info logs with timestamps, you should add the following to the
respective bird and bird6 configuration:

```
log stderr all;
```

see: <https://bird.network.cz/?get_doc&v=16&f=bird-3.html#ss3.2>

#### bird_exporter

By default `bird_exporter` will be enabled, when bird is enabled and expose prometheus metrics for *BIRD*.

To disable `bird_exporter` or change images or annotations, change the following parameteres:

```yaml
bird:
  birdExporter:
    enabled: true # default
    service:
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "9324"
    image:
      repository: openvnf/bird_exporter
      tag: v0.1.0
      pullPolicy: IfNotPresent
```

### VXLAN

There are two different ways available of connecting this service with another container.

The first one is the manual way, where the partners have to be configured with values.
The second one is using the *vxlan-controller* and the vxlans can be configured using annotations.

#### manual VXLAN setup [deprecated]

This feature might be deleted in future versions and is no longer supported!

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

#### VXLAN-Controller configuration

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

### VRRP

VRRP based on keepalived can be activated and configured.
It is possible to create multiple instances,
but the names and router ids have to be different.

For example:

```yaml

vrrp:
  enabled: true
  instances:
    # virtual IP address
  - vip: 192.0.2.1/24
    # instance name, must only be adjusted for parallel VRRP sessions
    name: instance01
    interface: eth0
    # route id, must only be adjusted for parallel VRRP sessions
    virtual_router_id: 50
    # priority, should differ between routing functions
    priority: 50
    authPath: secret
```

### PCAP [alpha]
To capture traffic in the pod, you have to enable `pcap` and configure it using environmental variables as described in the [pcap container documentation](https://hub.docker.com/r/travelping/pcap/):

```yaml
pcap:
  enabled: true
  env:
    IFACE: "eth0"
    DURATION: "300"
    FILTER: "80"
    FILENAME: "http"
```

### Rclone [alpha]
To publish captured traffic in the pod by pcap, you have to enable `Rclone` along `pcap` and
configure it using environmental variables. Use `RCLONE_REMOTE_NAME` to use
the correct remote and `RCLONE_REMOTE_PATH` for the correct destination path.
`Rclone` is defined generically through the container environment.
To find the name of the environment variable, first, take the long option name,
strip the leading --, change - to _ make upper case and prepend RCLONE_.
All available endpoints are described in the [official rclone documentation](https://rclone.org/commands/rclone_move/).
An [inotify](https://linux.die.net/man/1/inotifywait)-pattern is watching for captures, moving them from the directory `/data/finished`.


This container example-configuration enables authorisation for sftp through username and password:

```yaml
rclone:
  enabled: true
  env:
    RCLONE_REMOTE_NAME: "sftp" #Mandatory, when defining multiple devices, this is your selector.
# sftp
    RCLONE_CONFIG_SFTP_TYPE: "sftp"
    RCLONE_CONFIG_SFTP_HOST: "host.com" #hostname or ip of sftp-server
    RCLONE_CONFIG_SFTP_USER: "name"
    RCLONE_CONFIG_SFTP_PORT: "22"
    RCLONE_CONFIG_SFTP_PASS: "password" # Encoded "password". Leave blank to use ssh-agent
```

SFTP can also be authorised using private keys. Setting `useSSHkeyFile` will look for
the secret `rclone-ssh-key` in the appropriate namespace and mount it to `/etc/ssh` in
the containers filesystem. Rclone will look for the file using `RCLONE_CONFIG_SFTP_KEY_FILE`-
environment variable.

```yaml
rclone:
  enabled: true
  useSSHkeyFile: true
  env:
    RCLONE_REMOTE_PATH: "name/directory"
    RCLONE_REMOTE_NAME: "sftp" #Mandatory,
    RCLONE_CONFIG_SFTP_TYPE: "sftp"
    RCLONE_CONFIG_SFTP_HOST: "host.com" #hostname or ip of sftp-server
    RCLONE_CONFIG_SFTP_USER: "name"
    RCLONE_CONFIG_SFTP_PORT: "22"
    RCLONE_CONFIG_SFTP_PASS: "" # Encoded, blank for agent.
    RCLONE_CONFIG_SFTP_KEY_FILE: "/etc/ssh/key.pem"
```
Note that this secret `rclone-ssh-key` is not created automatically when deploying this helm chart, but needs
to be manually prepared by the user like so:

```bash
kubectl create secret generic rclone-ssh-key --from-file=/path/to/key.pem -n <namespace>
```

This container example-configuration enables authorisation for s3 through access-key and secret-access-key:
```yaml
rclone:
  enabled: true
  env:
    RCLONE_CONFIG_S3_TYPE: "s3"
    RCLONE_CONFIG_S3_ENV_AUTH: "false"
    RCLONE_CONFIG_S3_ACCESS_KEY_ID: "<sensitive>"
    RCLONE_CONFIG_S3_SECRET_ACCESS_KEY: "<sensitive>"
    RCLONE_CONFIG_S3_REGION: "s3-<region>"
    RCLONE_CONFIG_S3_ACL: "private"
    RCLONE_CONFIG_S3_FORCE_PATH_STYLE: "false"
```

Note that using `rclone_move` implies that transferred files will be removed from
the source path `data/finished`. This keeps the containers memory-footprint manageable
and enables file-cycling. If the process crashes during transfer no garbage data will remain
on the destination address and you will notice a `Terminated` in the container log.
When attempting to push duplicate files they will be removed from the source path but
not overwritten/modified on the destination if [MD5/SHA](https://github.com/ncw/rclone#features)
checksums and file-name are the same on both ends.
Be aware this can cause data loss, if you were happen to lose access to the data at
destination. Consider testing first using `--dry-run` flag first.

### Router Advertisement Daemon
To enable router advertisement of IPv6 routing CGWs, enable the daemon as follows:

```yaml
radvd:
  enabled: true
  config: |
    <add configuration here>
```

The configuration is described in the [radvd documentation](https://linux.die.net/man/5/radvd.conf) itself.

### Monitoring

The monitoring component of *CGW* supports ICMP echoes to defined endpoints and exposes it via an
http endpoint in prometheus format.

By default the component will send pings to the address stated in `ipsec.remote_ping_endpoint` from the address
configured in `ipsec.local_ping_endpoint`.

A service will be exposed and will be scraped automatically by common configured prometheus instances.

By default the service will be called `<release name>-cgw` and the metrics will be available at
`http://<release name>-cgw:9427/metrics`

#### Configure targets

To configure additional targets or source addresses, you have to configure the values as follows:

```yaml
pingExporter:
  targets:
    - sourceV4: 192.0.2.1          # Source address of ICMP requests
      sourceV6: "2001:0DB8:1::1"   # Source address of ICMP requests
      pingInterval: 5s             # interval for ICMP requests
      pingTimeout: 4s              # timeout for ICMP requests
      pingTargets:                 # list of ICMP targets
        - pingTarget: 192.0.2.10
        - pingTarget: 198.51.100.1
    - sourceV4: 192.0.2.2
      sourceV6: "2001:0DB8:2::2"
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - pingTarget: 203.0.113.1
        - pingTarget: "2001:0DB8:2::10"
```
All parameters are required!

For more informations refer to the [ping-exporter documentation](https://github.com/travelping/ping-exporter/blob/v0.6.0/README.md#multiple-ping-configurations).

When targets are set in this way, the usage of `ipsec.remote_ping_endpoint` and `ipsec.local_ping_endpoint` will
be automatically disabled.

#### <a name="disable_ping-prober"></a>disable ping-prober

If *ping-exporter* is configured (see above) the ping-prober can be disabled.
If the manual IPSEC configuration is used, the ping-prober MUST be disabled.

Disable the ping-prober:

```yaml
pingProber:
  enabled: false
```

### Pod wide configurations

#### additional pod annotations

Besides the default annotations to the pod, you can add additional ones by adding:

```yaml
additionalAnnoations:
  <your annotations here>
```

#### enable IPv6 routing

The additional annotations can be used to enable IPv6 Routing by setting:

```yaml
additionalAnnotations:
  security.alpha.kubernetes.io/unsafe-sysctls: net.ipv6.conf.default.forwarding=1,net.ipv6.conf.all.forwarding=1
```

#### Run CGW on exclusive nodes:

For activate this features setup nodeSelector and tolerations:
```
nodeSelector:
  cgw-service: "true"

tolerations:
- key: "node-role"
  operator: "Equal"
  value: "cgw-services"
  effect: "NoSchedule"
```
And add label and taint to the right nodes, for example on node1:
```
kubectl label nodes node1 cgw-service=true
kubectl taint nodes node1 node-role=cgw-services:NoSchedule
```

## Utilities

### debug container

By default a debug container with networking tools will be created.

If this is not desired, disable it as follows:

```yaml
debug:
  enabled: false
```
