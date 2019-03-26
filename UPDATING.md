# Update manual for CGW

<!-- toc -->

* [1.0.0](#100)
  * [disabled sections](#disabled-sections)
  * [manual config is new default for `ipsec`](#manual-config-is-new-default-for-ipsec)
  * [Services for IPSEC and VXLAN](#services-for-ipsec-and-vxlan)
* [pre 1.0](#pre-10)
  * [from version `= 0.10.0`](#from-version--0100)
    * [ping-exporter update](#ping-exporter-update)
  * [to version 0.7.0-alpha.4 or later](#to-version-070-alpha4-or-later)
    * [VXLAN controller annotations](#vxlan-controller-annotations)

<!-- tocstop -->

## 1.0.0

In version `1.0.0` of CGW a lot of defaults changed in a breaking manner, therefore it is assumed that your configuration will also be affected.

### disabled sections

By default all components of CGW are disabled by default besides the `debug` container.
Therefore the equivalent default looks like the following:

```yaml
debug:
  enabled: true

ipsec:
  enabled: false
  service:
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

Add a `enabled` section to all components you want to used!

### manual config is new default for `ipsec`

If you are NOT using the manual config for IPSEC, meaning providing a complete Strongwan config you have to add the following:

```yaml
ipsec:
  manualConfig: false
```

If it is already set to `true` you can either keep it or remove it.

### Services for IPSEC and VXLAN

If you are still using services for vxlan (without using vxlan-controller) and/or the service for ipsec itself,
you have to change the following, as the parts moved:

```yaml
ipsec:
  service:  # was `service` instead of `ipsec.service` before
    enabled: true
    <all settings from `service` go here>

vxlan:
  service:  # was part of the general `service` before and is split now
    enabled: true
```

## pre 1.0

### from version `<= 0.9.0` to `>= 0.10.0`

#### ping-exporter update

As the configuration format of the *ping-exporter* changed upstream, the configurations have to
be updated.

The old config was in the following format:

```yaml 
pingExporter:
  targets:
    - sourceV4: 192.0.2.1          
      sourceV6: "2001:0DB8:1::1"   
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - 192.0.2.10     <--- here
        - 198.51.100.1   <--- here
    - sourceV4: 192.0.2.2
      sourceV6: "2001:0DB8:2::2"
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - 203.0.113.1       <--- here
        - "2001:0DB8:2::10" <--- here
```

and has to be changed to the new one:

```yaml 
pingExporter:
  targets:
    - sourceV4: 192.0.2.1          
      sourceV6: "2001:0DB8:1::1"   
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - pingTarget: 192.0.2.10     <--- here
        - pingTarget: 198.51.100.1   <--- here
    - sourceV4: 192.0.2.2
      sourceV6: "2001:0DB8:2::2"
      pingInterval: 5s
      pingTimeout: 4s
      pingTargets:
        - pingTarget: 203.0.113.1       <--- here
        - pingTarget: "2001:0DB8:2::10" <--- here
```

### to version 0.7.0-alpha.4 or later

#### VXLAN controller annotations

Due to the change to using the *openvnf* repositories for VXLAN controller,
the default keys for the annotations also changed.

The default in this version is:

```
vxlanController:
  annotationKey: vxlan.openvnf.org/networks
  metadataKey: vxlan.openvnf.org
```

If your cluster uses an older version of the VXLAN Controller, you have to set
the values manually in your `values.yaml` file to:

```
vxlanController:
  annotationKey: vxlan.travelping.com/networks
  metadataKey: vxlan.travelping.com
```

or the values used in your cluster.
