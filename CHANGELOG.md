# Changelog
## pre 1.0.0
### 0.6.0

- add flag to use manual configuration for ipsec-config of Strongswan
- add usage of iptables container to firewall pod, enable by default and set it to very restrictive
  - **all your traffic will be blocked to the container, if you do not overwrite the firewall config!**
- add flag to disable ping-prober if not needed or ping-exporter is used
- add debug container as first container including networking tools

### 0.5.0

- add configurable keys for vxlan controller annotations
- add ping-exporter to expose metrics for ICMP Echo requests
- add feature to set static IP addresses outside of the scope of
  vxlan-controller
- add option to disable usage of VTI interfaces for IPSEC

### 0.4.0
-  add cgw-exporter to expose ICMP echo metrics for the service
