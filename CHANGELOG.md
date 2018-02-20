# Changelog
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
