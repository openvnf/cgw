# Update manual for CGW

<!-- toc -->

* [pre 1.0](#pre-10)
  * [from version `= 0.10.0`](#from-version--0100)
    * [ping-exporter update](#ping-exporter-update)
  * [to version 0.7.0-alpha.4 or later](#to-version-070-alpha4-or-later)
    * [VXLAN controller annotations](#vxlan-controller-annotations)

<!-- tocstop -->

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
