# Policy vs Route based VPN

<!-- toc -->

* [what is policy based VPN](#what-is-policy-based-vpn)
* [what is route based VPN](#what-is-route-based-vpn)
* [Caveat with VTI interfaces](#caveat-with-vti-interfaces)

<!-- tocstop -->

## what is policy based VPN

The default routing mode ode Strongswan and also the older model of IPSEC VPNs in general
is *policy based routing*.

As the name suggests, the corresponding software, in this case Strongswan, will add policies into the Kernel.
These polices will either match your packets and therefore encrypt them and send them over the tunnel to the right destination, or they will not match the packets and therefore not touch them at all.

On Linux machines, you can have a look into the installed policies with the following command:

```sh
ip -6 xfrm policy
```

One example result for a VPN is the following:

```
src 2001:db8:1::/48 dst ::/0
        dir out priority 399999
        tmpl src 2001:db8:0:1::1 dst 2001:db8:0:2::1
                proto esp spi 0xbf6dcd82 reqid 2 mode tunnel
src ::/0 dst 2001:db8:1::/48
        dir fwd priority 399999
        tmpl src 2001:db8:0:2::1 dst 2001:db8:0:1::1
                proto esp reqid 2 mode tunnel
src ::/0 dst 2001:db8:1::/48
        dir in priority 399999
        tmpl src 2001:db8:0:2::1 dst 2001:db8:0:1::1
                proto esp reqid 2 mode tunnel
```

These three policies depend on their direction as mentioned in lines 2, 6 and 10.
When the source and the destination addresses match the corresponding source and destionation
range, the packets will treated by using the protocol defined in lines 4, 8 and 12.
In this case ESP (Encapsulating Security Payload).

This is commonly used for VPN, because no routes have to be set or agreed on.

## what is route based VPN

*Route based VPN* uses a virtual interface, called *Virtual Tunnel Interface* or VTI for short.
In the case of Linux, this is actually implemented like a tunnel and looks from the user perspective
like other tunnels including GRE and VXLAN.

This tunnel interface can therefore be used, to route traffic over this interface.
Every packet, which reaches the interface, will be marked by the Kernel number.
After that, the packet will be matched by a XFRM rule and therefore encrypted and send to the other IPSEC Gateway.

TODO: Add picture

Therefore the configuration is a bit more complicated, because of the created tunnels and routes.

The benefit of this solution is though, that also other routing mechanisms are working over the VPN tunnels,
for example BGP and OSPF.
Tue to this, it is "easily" possible to create high available architectures with failover between tunnels.

Due to this, *Route Based VPN* is the preferred way of setting up VPNs at Travelping.

For further information please look at the [Strongswan Documentation](https://wiki.strongswan.org/projects/strongswan/wiki/RouteBasedVPN)

## Caveat with VTI interfaces

As described above, in the case of Linux, the VTI interfaces are not implemented as special interfaces, like in some other operating systems, but as a virtual tunnel.

Therefore you have to use the following command:

```sh
ip tunnel add <name> local <local IP> remote <remote IP> mode vti key <number equaling the mark>
```

For debugging purposes it makes sense, to set the `<local IP>` and `<remote IP>` to the same IP as used in the VPN configuration.

Further to be able to route traffic over the VTI interface, you have to assign a network and an IP address to the VTI interface.

So when the address `2001:db8:100::0/127` is assigend to the interface `vti1`, the corresponding routes will be set like the following:

```sh
ip -6 route add ::/0 via 2001:db8:100::1`
```

Here it though does not matter what IP addresses are used as long as they are not interfering with the ones used in the network already.
Because the packets will be marked when going through the VTI interface and the Ethernet header will be removed, the IP address of the other side, in this case `2001:db8:100::1/127` does not need to exists on the other end and is just virtual to us.

