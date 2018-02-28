# Changelog
## 0.4.0
### added features
#### Calico static routes
Support to set static routes on all hosts, which do not run CGW, for use in conjunction with calico.

This feature will be used to connect two sides using CGW with IPSEC, where at least one is a Kubernetes cluster
using Calico as a networking layer.

Please consider the [README](README.md) for usage.

## 0.3.0
### incompatible changes
#### PSK

The PSK for IPSEC has now to be set in the field `value:` of the psk key.

Now:

```yaml
ipsec:
  psk:
    value: <the secret psk>
```

Before:

```yaml
ipsec:
  psk: <the secret psk>
```

This is due to the feature of using kubernetes secrets instead of values in the helm config itself.
