# General values

These values are not specific to a single component of the CGW, but the CGW
as a whole.

## root level settings

### sysctls

To expose `sysctl` settings for the security context of the pod, you can add
them to `.Value.sysctls`.

Example:

```yaml
sysctls:
  - name: net.ipv4.conf.all.forwarding
    value: "1" 
  - name: net.ipv4.conf.all.rp_filter
    value: "2"
```

### Additional Pod Specs

For pod specs not yet defined, you can add them as follows.

For adding a `nodeSelector`, which is part of the pod spec, you can add:

```yaml
additionalPodSpec:
  nodeSelector:
   ...
```
