# Route-based VPN

If you have not already read up on the differences between [route-based and policy-based VPN](../concepts/policy_route_based_vpn.md), please do so.

We will use the result of the tutorial on [policy based vpn](./setup_ipsec.md) as a starting point.
So if you did not went through this tutorial first, please do so.

<!-- toc -->

* [current configuration](#current-configuration)
* [Changes to Strongswan](#changes-to-strongswan)
  * [subnets](#subnets)
* [setting up VTI interfaces](#setting-up-vti-interfaces)
* [add routes](#add-routes)

<!-- tocstop -->

## current configuration

```yaml
ipsec:
  manualConfig: true # default is false
  strongswan:
    ipsecConfig:
      ipsec.simple_route_based_config.conf: |
        # ipsec.conf - strongSwan IPsec configuration file
        conn sts-base
            dpdaction=restart
            closeaction=restart
            auto=start
            ike=aes256gcm16-prfsha384-curve25519!
            esp=aes256gcm16-prfsha384-curve25519!
            keyingtries=%forever
            forceencaps=no
            lifetime=28800s
            ikelifetime=86400s
            keyexchange=ikev2
            mobike=no
            leftauth=psk
            rightauth=psk

        conn second-site
            also=sts-base
            leftsubnet=2001:db8:1::/48
            left=2001:db8:0:1::1
            rightsubnet=::/0
            right=2001:db8:0:2::1
        
    ipsecSecrets:
      ipsec.simple_route_based_config.secrets: |
        # ipsec.secrets - strongSwan IPsec secrets file
        2001:db8:0:2::1 : PSK "CorrectHorseBatteryStaple"
```

The above is the resulting configuration from the policy base tutorial.
We will change this further to get to a working configuration with route based VPN.

## Changes to Strongswan

As described in the concepts, we will use a *Virtual Tunnel Interface (VTI)* as a target for routing through the tunnel.
Change the Configuration as follows:

```yaml
ipsec:
  strongswan:
    conn second-site
      mark=42
```

`mark` sets the value used to mark the packets to use in conjunction with a *Virtual Tunnel Interface*.

If you have multiple VPN connections, you have to make sure, that the numbers used as a value for `mark` are unique to this confiuguration.

### subnets

In the case of route-based vpn, it is common to set both subnets to `::/0` or `0.0.0.0/0` and decide based on the routes, which traffic to send over link.

Therefore we will change the networks to the following:

```yaml
ipsec:
  strongswan:
    conn second-site
      leftsubnet=::/0
      rightsubnet=::/0
```

Often other routers will not accept the setting though, and therefore it can make sense to restrict the networks further as in the starting configuration on the top.

## setting up VTI interfaces

To route traffic over the VPN connection, a VTI interface has to be created.
As described in the tutorial for [imperative IP configuration](./imperative_ip_configuration.md),
we will do so using the init script:

```yaml
initscript:
  enabled: true
  env:
    MARK: "42"
    
    LEFT_ENDPOINT: "2001:db8:0:1::1"
    RIGHT_ENDPOINT: "2001:db8:0:2::1"
    
    VIRTUAL_ADDRESS_LEFT_CIDR: "fd2d:3ea6:d58c:f2c9::0/127"
    VIRTUAL_ADDRESS_RIGHT: "fd2d:3ea6:d58c:f2c9::1"
    
    #<add routing variables here>
    
  script: |
    set -xeu
    
    echo "add VTI interface\n"
    ip tunnel add vti${MARK} mode vti local $LEFT_ENDPOINT remote $RIGHT_ENDPOINT key $MARK
    ip -6 address add $VIRTUAL_ADDRESS_LEFT_CIDR dev vti${MARK}
    ip link set vti${MARK} up
    #<add routing rules here later>
```
    
In the `env` section of the initscript, we will define our parameters as environmental variables, as it eases reusability and increases readability.

The value `MARK` is used to the define, what key will be set for the packets traversing the interface.
This values has to be the same as the one configured in the Strongswan section before.

`LEFT_ENDPOINT` and `RIGHT_ENDPOINT` are the endpoints of the VPN connection as configured in the Strongswan section.

`VIRTUAL_ADDRESS_LEFT_CIDR` and `VIRTUAL_ADDRESS_RIGHT_CIDR` are two IP addresses, which will be used for routing descisions by the kernel.
As these IP addresses will not be seen on the other side, you just have to use them out of a range, which is not used in you network already.
In this case we use ULA IP addresses.

As shown in line 16, we create the VTI interface as a virtual tunnel interface with the actual endpoints of the tunnel.
Further the `key` parameter is here set to the value of `MARK`.

We add the virtual IP address for routing to the interface in line 17.

Last, we enable the tunnel by setting it in the `up` state.

## add routes

To be able to transfer traffic over the tunnel,  we have to add targets and its routes to the routing table.

First we will add the following variable to the configuration (line 12 in the above config):

```
ROUTED_NETWORK: "2001:db8:10::/48"
```

Second we will add the following routes at the place marked above in line 19:

```
echo "add routes for VPN\n"
ip -6 route add ${ROUTED_NETWORK} via ${VIRTUAL_ADDRESS_RIGHT}

```

This setting will now send the traffic with target of `2001:db8:10::/48` over the VPN tunnel.
As described in the concepts, the right endpoint does not need to have the address assigend to an interface,
as it is just virtual on our side.
