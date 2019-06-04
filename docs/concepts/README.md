# Concepts

This part of the documentation will explain the overall ideas of the CGW and the concepts of the
interworking of the components.

If you want to be guided step by step through the different components, have a look at the *[Tutorials](../tutorials/README.md)*.

If you are just looking for a certain task, and already know the concepts and the details of the components, have a look at the *[How Tos](../how-tos/README.md)*.

## Parts

* [Policy vs Route based VPN](./policy_route_based_vpn.md)


### Models

Models describe a certain architecture on implementing connectivity to other sides.
These my include VPN, Firewalling, and Routing or any combination of these.

Further to implement High Availability the architecture has to provide
measures to retain service if any of the components fail. 


#### simple models

* [Site-to-site route-based VPN (MODEL-1)](models/s2s-route-based-vpn.md)
* [BGP routing with external default route (MODEL-2)](models/bgp-default-route.md)
* [Local Breakout for specific IP range (MODEL-3)](models/local-breakout-manual.md)

#### multi-protocol models

* [BGP routing over a VPN secured link (MODEL-4)](models/vpn-bgp-default-route.md)_

#### High Available models

* [HA routing via two routers on our side (MODEL-5)](models/bgp-ha-one-side.md)
* [HA routing via two routers on each side with full
  mesh (MODEL-6)](models/bgp-ha-two-sides-full.md)
* [HA routing via two routers on each side over VPN with full
  mesh (MODEL-7)](models/bgp-ha-tow-sides-full-vpn.md)


