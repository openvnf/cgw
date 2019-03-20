# Setting up a VPN connection with IPSEC

In the current implementation of *CGW* we will use Strongswan as the software used for VPN termination
using the IPSEC protocol.

In the following, we will go through an example of setting up an IPSEC connection for the CGW Helm Chart.
The focus is to get an understanding of the IPSEC part of the CGW, therefore, we will assume for this tutorial, that the [IP addresses](./imperative_ip_configuration.md) and interfaces are already set up.

<!-- toc -->

* [Preconditions](#preconditions)
* [enable Strongswan](#enable-strongswan)
* [setting Interface](#setting-interface)
* [Manual configuration of Strongswan](#manual-configuration-of-strongswan)
  * [ipsecConfig](#ipsecconfig)
    * [sts-base](#sts-base)
    * [second-site](#second-site)
    * [left and right](#left-and-right)
  * [ipsecSecrets](#ipsecsecrets)
* [further reading](#further-reading)

<!-- tocstop -->

## Preconditions

You have already an interface `inet0` configured, which is connected to the internet and has a public IP address.

For this demo, we will assume, that the configuration is the following: `inet0: 2001:db8:0:1::1/64`.

All the following confiugrations will be part of the `value.yaml` file you create for configuring the CGW Chart.
You can combine multiple parts of the configuration, therefore we will not repeat parts set in previous parts.

## enable Strongswan

To enable Strongswan to terminate IPSEC traffic, set the following:

```yaml
ipsec:
  enabled: true  # switch on the Strongswan IPSEC module
```

## setting Interface

If you have more than one interface in the pod, it does make sense, to specify on which interface Strongswan
should listen, as it narrows down the area of attacs.

To set the interfaces Strongswan shall bind on, set `ipsec.interfaces` with a comma seperated list of interfaces.

For example:

```yaml
ipsec:
  interfaces: "inet0"
```

## Manual configuration of Strongswan

The recommended way for this version of CGW is to use a manual Strongswan configuration.
There were other ways to configure VPNs in the past, but they are **depricated** and development
will not be continued for these methods in the future.

The framework for configurations of Strongswan is the following:

```yaml
ipsec:
  manualConfig: true # this is the default for now but could change in the future
  strongswan:
    ipsecConfig:
      ipsec.<myconnectionname>.conf: |
        <add your ipsec config here>
    ipsecSecrets:
      ipsec.<myconnectionname>.secrets: |
        <add your ipsec secret here>
```

The `ipsecConfig` sector will contain configurations for the different connections,
while the `ipsecSecrets` sector will contain the configurations of the secrets.

### ipsecConfig

Under `ipsecConfig` you can add multiple configuration, where each key is the corresponding filename.
For debugging it does make sense, to give it a reasonable name.

The content of this key is a block string, which is basically a Strongswan configuation file.
Therefore for all details of possible parameters please consult the [Strongswan documentation](https://wiki.strongswan.org/projects/strongswan/wiki/IpsecConf).

The following is a simple configuration for Route Based VPN (see below):

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
            mark=42
```

We will now go through the configuration line by line to explain the most common parameters beeing set.

#### sts-base

Starting in line 7 the connection `sts-base` is configured.
Everything which is indented further is part of this configuration (till line 20).

The first part is the default configuration, which will be inherited by the following configurations.

`dpdaction` defines, what will happen, if the other side does not send liveliness messages and so a dead peer is detected.
For site to site VPNs it is preferred to set it to `restart` as the CGW will try to create a new connection immediately.

`closeaction` is closely related and defines the action, when the other peer ends the connection with a closing message.
Also here `restart` should be used for site to site connections.

`auto` defines how Strongswan behaves, when it is started.
The options are `ignore`, `add`, `route` and `start`.
`ignore` actually ignores the whole connection and will not respond even to connection requests from the other side.
`add` will add the connection and respond to requsts from the other side, but not start a connection itself.
This is useful in the *road warrior* scenario.
`route` will install a trap into the network stack and not do anything immediately. If the first packet, which matches the parameter of the connection though, it will try to create a connection.
With `start` it will immediately try to open up a connection. This setting is preferred in site to site scenarios.

`ike` and `esp` are setting the cryptographic algorithms, which are preferred or even enforced (when ending with `!`) by Strongswan.
Often these parameters are given to you by the other side, you try to connect to.
If this is not the case, and you do not control the other side, you have to negotiate, what their router will support.
In the case you are controlling the both ends of the tunnel, you can have a look at [Cryptographic Algorithms](../concepts/cryptographic_algorithms.md) or just stick with the setting above.

The `ike` parameter is setting the algorithms for the IKE phase (first phase), which is used for the control traffic and key exchange, whereas the `esp` parameter is setting the algorithms for the ESP part, which encapsulate the actual data traffic.

`keyingretries` defines how often it tries to choose now keys between the peers, when the negotiation fails.
This value can be set to all positive integers or to `%forever`.

`lifetime` and `ikelifetime` defines the duration of the connections, when they are not disconnected my other means.
After this period the ESP or IKE connection will be rekeyed respectively.

`keyexchange` selects, which protocol will be used for key exchange.
If it is your choise, you should use `ikev2`.
If the other party is not able to support it, you can choose `ikev1`.

`mobike` enables or disables the usage of the [MOBIKE](https://wiki.strongswan.org/projects/strongswan/wiki/MobIke) protocol.
This is not in general advised for site to site links.

`leftauth` and `rightauth` are defining, which method is used to 

#### second-site

The second part of the configuration stating at line 22 is the actual connection we are creating.

`also` defines, from which connection we inherit all parameters.
These will then be extended or overwritten in this configuration.

`leftsubnet` and `rightsubnet` set the subnets, for which traffic will be transferred of the connection or what packets will be allowed.
If you have not had a look at [Route-based vs Policy-based VPN](../concepts/policy_route_based_vpn.md), please read it first.

In the case of route-based vpn, it is common to set both subnets to `::/0` or `0.0.0.0/0` and decide based on the routes, which traffic to send over link.
Often other routers will not accept the setting though, and therefore the example above also shows a specific network.

`left` and `right` set the IP, which is used on the corresponding nodes.
Besides setting a specific IP, it is also possible to set the value to `%any` to allow connections from any IP address.
This is common in the road warrior scenario but uncommon in site to site VPNs.

`mark` sets the value used to mark the packets to use in conjunction with a *Virtual Tunnel Interface*.
How to set uon an interface like that, have a look at the corresponding [tutorial](./vti_interface.md).

#### left and right

Strongswan uses `left` and `right` as prefixes for a lot of parameters to seperate between both sides.
There is no clear seperation which one is the current configured CGW, so you can use the same configuration on both sides.

It is very common though, to use the `left` side for the CGW you are configuring and use the `right` side for the "other side".

### ipsecSecrets

The `ipsecSecrets` part contains the acutal secrets for the VPN connection.
This can either be a preshared key or parameters for the used private key.

The following shows the case for using a preshared key:

```yaml
ipsec:
  strongswan:
    ipsecSecrets:
      ipsec.simple_route_based_config.secrets: |
        # ipsec.secrets - strongSwan IPsec secrets file
        2001:db8:0:2::1 : PSK "CorrectHorseBatteryStaple"
```

The first part of the line 6 is the ID of the other peer, which is by default the IP address,
but can also be a FQDN, an email address, `%any` or `%any6`.

`%any` and `%any6` match all IPv4 and IPv6 addresses respectively.

Further follows the mode for the authentication and finally the parameters for it.
In this case `PSK` for preshared key and `CorrectHorstBatteryStaple` for the PSK itself.

## further reading

If you want to set up VPN with certificates, please have a look at the corresponding [Certificate Based VPN](./certificate_based_vpn.md).
