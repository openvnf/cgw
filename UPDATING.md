# Update manual for CGW

<!-- toc -->

* [pre 1.0](#pre-10)
  * [to version 0.7.0-alpha.4 or later](#to-version-070-alpha4-or-later)
    * [VXLAN controller annotations](#vxlan-controller-annotations)

<!-- tocstop -->

## pre 1.0

### to version 0.7.0-alpha.4 or later

#### VXLAN controller annotations

Due to the change to using the ****openvnf* repositories for VXLAN controller,
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
