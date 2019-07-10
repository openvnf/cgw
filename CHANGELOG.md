# Changelog

## General Notice

Deprecated features or components might be removed in later versions without change in major version number!

## 1.0
 
### 1.3.0
- change deployment strategy to `Recreate` as we had problems with duplicate
  address detection of not yet dead pods.

### 1.2.2
- reduce packaged helm chart file size from 240kbyte to 21kbyte

### 1.2.1

- fix mode values for file access of init script and radvd-config
- move `terminationGracePeriodSeconds` into Podspec
- fixes validation error for Helm `2.14` with this chart

### 1.2.0

- enable log to standard out for *bird* containers.

### 1.1.0

- update version of `pcap` to `1.2.1`
- change default resources to lower values

### 1.0.2

- update version of `bird_exporter` to fix non-propagation of container startup
  arguments.

### 1.0.1

- update `vnf-bird` to `1.0.2` as `bird6` was forgotten to be installed

### 1.0.0

- configuration [breaking]
  - move `service` section of `ipsec` under `ipsec` section in value file
  - move `image` section of `ipsec` under `ipsec` section in value file
  - move `pullSecrets` section to root and remove defaults
  - move `setRouteDefaultTable` section under `ipsec` section
  - move `useEnvConfig` section under `ipsec` section
- new defaults [breaking]
  - change manual config for IPSEC to be the new default
  - disable `ipsec` by default
  - disable `iptables` by default
  - disable `pingProber` by default
  - disable `pingExporter` by default
  - disable `ipsec.service` by default
- add service for vxlan and move it out of IPSEC service [breaking]
- updated software versions [breaking]
  - update `ping-prober` container to alpine `3.9`
  - update `pcap` to `1.1.0`
  - update `travelping/nettools` image to `1.10.0`
- udate software versions
  - update `vnf-bird` to `1.0.1`, which uses Fedora and bird `1.6.6`
- move all repositories to quay.io for security checking
- remove the chart name (*cgw*) from the container names in the pod
- deprecation
  - configure GRE using the `gre` component is deprecated
  - configure IP addresses using `ipSetup` is deprecated
  - using vxlan-connector (`vxlan`) is deprecated
    - use vxlan-controller instead
  - configure IPSEC without using `manualConfig` is deprecated
- double `ping-exporter's` resources to mitigate wrong results (https://github.com/openvnf/cgw/pull/31)
- added `filename` to *rclone* to enable naming trace-files.

## pre 1.0.0

### 0.10.0

- update *ping-exporter* to `0.6.0`
  - [breaking] configuration of ping-exporter changed (see [UPDATING](./UPDATING.md))
- major changes to *rclone*
  - fixed known issue in *rclone* to enable proper file cycling.
  - added `useSSHkeyFile` to *rclone* to utilise ssh-keys properly.
  - enhanced readme for *rclone* to describe configurations using ssh-keys.
  - removed default values from *rclone* to enable generic endpoints without overwrites.

### 0.9.0

- update nettools image to `1.9.0`
- update ping-exporter to `0.5.1`
- add support for pcap-file sftp-pushing using *rclone*
- change *pcap* to version 1.0.2

### 0.8.1

- add default resource requests and limits for initIP container
- add default resource requests and limits for pingExporter container
- change pcap container image to version `1.0.1` for a bugfix

### 0.8.0

- add support for Router Advertisement Daemon (radvd)
- add support for pcap capturing using *tshark*
- change *ping-exporter* to version 0.5.0

### 0.7.0

- change name of ipsec container
- add flag to enable ipsec component
- add documentation for using `iptables` with CGW
- add support for certificate based VPN
- add support for using VRRP for internal router redundancy [alpha]
- update version of `vnf-ipsec` to `1.3.1` to fix problem with enabled
  `farp` plugin
- [breaking] update VXLAN-Controller to use image from new docker repository and
  use corresponding annotations
  - from `aialferov/kube-vxlan-controller-agent` to `openvnf/kube-vxlan-controller-agent`
  - If the default settings have been used on current clusters, the value file has to be changed to set the old names explicitly
- [bugfix] strongswan configmap will not be created, if ipsec is disabled
- [bugfix] pingExporter configmap will not be created, if pingExporter is disabled
- add `selector` to deployment spec, which is required in newer versions of Kubernetes and encouraged in older ones
  - see <https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#selector>
- disable `init-ip` init container to set local ping endpoint if `ipsec` is not enabled
- update vnf-ipsec to 1.4.0
  - also fixes *CVE-2018-17540*
- add parameter for additional pod annotations

### 0.6.0

- add flag to use manual configuration for ipsec-config of Strongswan
- add usage of iptables container to firewall pod, disabled by default
- add flag to disable ping-prober if not needed or ping-exporter is used
- add debug container as first container including networking tools
- add init script container to run custom initialization
- add BIRD as BGP daemon
- add bird_exporter to expose BIRD metrics in prometheus format
- add checksums of configmaps and secrets to deployment to redeploy and restart
  them when the configuration changes

### 0.5.0

- add configurable keys for vxlan controller annotations
- add ping-exporter to expose metrics for ICMP Echo requests
- add feature to set static IP addresses outside of the scope of
  vxlan-controller
- add option to disable usage of VTI interfaces for IPSEC

### 0.4.0
-  add cgw-exporter to expose ICMP echo metrics for the service
