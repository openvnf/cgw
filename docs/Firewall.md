# Securing CGW using a firewall

To secure the CGW pod against unwanted traffic, it is possible to use `iptables` as a firewall.
This is especially important if a public IP is attached to the pod.

<!-- toc -->

* [Concepts](#concepts)
  * [available tables](#available-tables)
* [enable `iptables` firewall configuration](#enable-iptables-firewall-configuration)
* [configure `iptables` rules](#configure-iptables-rules)
  * [basic format](#basic-format)
* [Useful configuration blocks by example](#useful-configuration-blocks-by-example)
  * [setting the default policies of the chain](#setting-the-default-policies-of-the-chain)
  * [allow loopback traffic](#allow-loopback-traffic)
  * [allow traffic from calico network](#allow-traffic-from-calico-network)
  * [allow traffic from and to your VTI interfaces](#allow-traffic-from-and-to-your-vti-interfaces)
  * [Allow ICMP traffic on the public interfaces](#allow-icmp-traffic-on-the-public-interfaces)
  * [Allow IPSEC traffic](#allow-ipsec-traffic)
  * [Allow ICMP on all interfaces](#allow-icmp-on-all-interfaces)
  * [Allow routing between two interfaces](#allow-routing-between-two-interfaces)
  * [Rejecting traffic with a specific ICMP message](#rejecting-traffic-with-a-specific-icmp-message)
  * [Mangle TCP packets to decrease packet size](#mangle-tcp-packets-to-decrease-packet-size)
* [Examples](#examples)

<!-- tocstop -->

## Concepts

Below just some basics of the inner workings of `iptables` will be described.

The explaination of the syntax and sematics of `iptables` rules are out of the scope of this
documentation.
Please consider some of the following resources if you are not familiar with the rules yet:

* Suehring, Steve. Linux Firewalls : Enhancing Security with Nftables and Beyond. 4. ed. 2015.
* [netfilter project](https://www.netfilter.org/documentation/index.html)
* [ubuntuusers wiki (german)](https://wiki.ubuntuusers.de/iptables2/)
* [Arch Linux wiki](https://wiki.archlinux.org/index.php/iptables)

Further you should get a basic understanding of the basic working of `iptables` before continuing with firewall configuration, including tables, chains and rules.

### available tables

The following diagram shows the flow and used tables of `iptables`:

```
                               XXXXXXXXXXXXXXXXXX
                             XXX     Network    XXX
                               XXXXXXXXXXXXXXXXXX
                                       +
                                       |
                                       v
 +-------------+              +------------------+
 |table: filter| <---+        | table: nat       |
 |chain: INPUT |     |        | chain: PREROUTING|
 +-----+-------+     |        +--------+---------+
       |             |                 |
       v             |                 v
 [local process]     |           ****************          +--------------+
       |             +---------+ Routing decision +------> |table: filter |
       v                         ****************          |chain: FORWARD|
****************                                           +------+-------+
Routing decision                                                  |
****************                                                  |
       |                                                          |
       v                        ****************                  |
+-------------+       +------>  Routing decision  <---------------+
|table: nat   |       |         ****************
|chain: OUTPUT|       |               +
+-----+-------+       |               |
      |               |               v
      v               |      +-------------------+
+--------------+      |      | table: nat        |
|table: filter | +----+      | chain: POSTROUTING|
|chain: OUTPUT |             +--------+----------+
+--------------+                      |
                                      v
                               XXXXXXXXXXXXXXXXXX
                             XXX    Network     XXX
                               XXXXXXXXXXXXXXXXXX
```
( This drawing was taken from the [Arch Wiki](https://wiki.archlinux.org/index.php/iptables#Basic_concepts) )

If not considering NATting, the tables of importance are `INPUT`, `OUTPUT` and `FORWARD`.

The INPUT and OUTPUT table are used for the traffic coming from and going into process on the machine itself.
Therefore for every software running in the pod, the rules for this specific software have to be added.

The FORWARD table is used for traffic only routed over this pod/node.

Attention: Protocols like VXLAN create a new device in the pod but use the underlying device for the encapsulated traffic itself.
Because of this, the VXLAN traffic has to be allowed on the underlying interface and the traffic from and to the VXLAN interface has to be considered seperately.

This also applies for other overlay protocols or encapsulations including IPSEC.

```
              +----------+            +------------+
              |          |            |            |
  +-------->  |   eth0   |  +------>  |   vxlan0   |
              |          |            |            |
              +----------+            +------------+
```

### dropping vs rejecting traffic

There are two differnt ways on blocking traffic: dropping or rejecting.

In the first case, the traffic is just silently dropped, in the second case,
the firewall will send an ICMP message with a reason, why the target is not reachable.

Concerning [RFC1122](https://tools.ietf.org/html/rfc1122#page-69) endpoints should send error messages when possible.
Also debugging inside the cluster gets easier, if it is clear wheather a port is blocked or the service behind it is not running.

On the contrary though, more traffic will be created when rejecting packets and it has been used in the past for
attacking other hosts (DDOS).

Therefore I would advise to use rejection inside a network perimeter, where rouge services are not expected to be the rule but an exception and use dropping the edges to the public internet.

Setting policies and [ICMP message types](#rejecting-traffic-with-a-specific-icmp-message) is described below.

## enable `iptables` firewall configuration

To enable iptables, you have to set the following values in your CGW confiuguration:

```yaml
iptables:
  enabled: true  # default is false
  ipv4Rules: |
    <add your rules here as described below>
  ipv6Rules: |
    <add your rules here as described below>
```

## configure `iptables` rules

The rules have to match the rules of the [iptables-save](https://linux.die.net/man/8/iptables-save) format, which will be used for the above mentioned file.

I will explain common parts of the configuration below.

Most rules can be applied to the configuration of both, IPv4 and IPv6, if not marked otherwise.

NOTE: You have to configure the firewall for both protocols to be effective!

### basic format

The format consists basically of three parts in a block, where each block can repeat.

The first part is the declaration of the table to be used in the format `*<tablename>`.

The second part are the rules themselves, each in a single line.
These match the syntax you would normally use on the command line.
The parameter of the table MUST be ommited though in the rules, because it is already defined by the first part.

The third part is the `COMMIT` statement, to commit the changes of the configuration.

These blocks can be repeated for different tables.

An example of a rules file:

```
*filter     <-- *table describes the iptables table to use
-A INPUT -i lo -j ACCPET  <-- command of changing rules equivalent to the one in the cli
COMMIT    <-- commits this table

*mangle   <-- use `mangle` table
-A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o inet0 -j TCPMSS --set-mss 1250 <-- another rule
COMMIT <-- commits this table
```

## Useful configuration blocks by example

### setting the default policies of the chain

To set the default policies of the firewalling chains, you can add the folowing:

```
*filter
## Block all traffic silently as default policy
## Take care because this can cause harm if wrongly configured
-P INPUT DROP
-P FORWARD DROP
-P OUTPUT DROP
COMMIT
```

Possible options are `ACCEPT` and `DROP`.

As the name *default policy* might suggest, for every packet, for which none of the defined rules match,
the default policy will be applied and the packet either be accepted or dropped.

Because of erroneous human behaviour while writing rules it is advised to set the default policy to `DROP` for increased security.
Never the less be carefull with this option during development to not lock yourself out.

For readability it is though advised to explicitly reject or drop unwanted traffic due to rules.

### allow loopback traffic

To allow loopback traffic from local services add the following lines to the configuration

```
## Allows all loopback (lo) traffic and drop all traffic to 127/8 that doesn't use lo
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d 127.0.0.0/8 -j REJECT
```

For IPv6 it will be:

```
## Allows all loopback (lo) traffic and drop all traffic to 127/8 that doesn't use lo
-A INPUT -i lo -j ACCEPT
-A INPUT ! -i lo -d ::1 -j REJECT
```

### allow traffic from calico network

For pods on a kubernetes cluster using calico you could add the following to allow traffic from the main interface:

```
## Allow all traffic from and to Calcio network
-A INPUT -i eth0 -j ACCEPT
-A OUTPUT -o eth0 -j ACCEPT
```

If you want to close the traffic further, you could also add further restrictions on protocols or IP addresses (see below).

For general seperation of namespaces and services it might though be useful to look into calicos native policy enforcement.

### allow traffic from and to your VTI interfaces

I you use *route-based VPN* with CGW you will create a virtual terminal interface to route the traffic to, you want to tunnel.

The following rules will accept all traffic coming from and going to the interfaces as well as routing:

```
## allow incoming and outgoing traffic on vti interface
-A INPUT -i vti42 -j ACCEPT
-A OUTPUT -o vti42 -j ACCEPT
## allow routing on vti42 only if gre is not used
-A FORWARD -i vti42 -j ACCEPT
-A FORWARD -o vti42 -j ACCEPT
```

If you though just need to have ICMP traffic from and to the CGW allowed for debugging and have a dedicated interface for connection to the connected service, for example through VXLAN, you can restrict the rules further:

```
## allow incoming and outgoing traffic on vti interface
-A INPUT -i vti42 -p icmp -j ACCEPT
-A OUTPUT -o vti42 -p icmp -j ACCEPT
## allow routing on vti42 only if gre is not used
-A FORWARD -i vti42 -o service0 -j ACCEPT
-A FORWARD -o vti42 -i service0 -j ACCEPT
```

Of course you could even limit the traffic to specific protocols, ports or IP addresses (see below).


### Allow ICMP traffic on the public interfaces

On some deployment of CGW, there will an interface be attached, which provides a public IP address.

To allow ICMP traffic to and from the interface add the following:

```
## allow icmp on inet0 (the interface with the public ip address)
-A INPUT -i inet0 -j ACCEPT -p icmp
-A OUTPUT -o inet0 -j ACCEPT -p icmp
```

### Allow IPSEC traffic

This scenario assumes, that an interface with a public IP address is used (see above).
If this is not the case, either the interfaces has to be changed or the rules can be ommited,
if all traffic on the Calico interface is allowed.

IPSEC can use three different kinds of traffic in normal setups.

The first is the ESP protocol, which is mostly used between to sites for the data traffic.

The second is UDP port 500, which is used for IKE negotiations and NAT detection.

The third one is UDP port 4500, which will be used for IKE and data,
when a NAT is detected or UDP encapsulation is enforced.

In cases, where ESP is known to be not working or no NATs exists, either the one or the other rule can be removed.

```
## add rules for ipsec on external interface
# Only allow IPSEC traffic from and to the other side gateway
# ESP
-A INPUT  -p esp -i inet0 --src 192.0.2.1 -j ACCEPT
-A OUTPUT -p esp -o inet0 --dst 192.0.2.1  -j ACCEPT

# IKE (udp 500)
# inet0 = device with public ip address, 192.0.2.1 = IP of the remote gateway
-A INPUT  -p udp -i inet0 --sport 500 --dport 500 --src 192.0.2.1  -j ACCEPT
-A OUTPUT -p udp -o inet0 --sport 500 --dport 500 --dst 192.0.2.1  -j ACCEPT

# NAT-Traversal
-A INPUT  -p udp -i inet0 --sport 4500 --dport 4500 --src 192.0.2.1  -j ACCEPT
-A OUTPUT -p udp -o inet0 --sport 4500 --dport 4500 --dst 192.0.2.1  -j ACCEPT
```

### Allow ICMP on all interfaces

To enable ICMP on all interfaces, you can add the following rules:

```
## Allow all ICMP messages
-A INPUT  -p icmp -j ACCEPT
-A OUTPUT -p icmp -j ACCEPT
-A FORWARD -p icmp -j ACCEPT
```

### Allow routing between two interfaces

The following example shows a symmetric allowed connection between two interfaces:

```
## allow routing between eth0 and eth1
-A FORWARD -i eth0 -o eth1 -j ACCEPT
-A FORWARD -o eth0 -i eth1 -j ACCEPT
```

Of course the filtering can also be different in both directions and more specific concerning protocols and ports.

### Rejecting traffic with a specific ICMP message

You can reject traffic with ICMP messages meeting more closely the reason for the blocking.
One example is the following:

```
-A INPUT -i eth1 -j REJECT --reject-with icmp-host-prohibited
```

In this example, traffic reaching the host over interface `eth1` from the outside will be rejected with a `host prohibited` message.

The following messages are available:

* <add messages here>

### Mangle TCP packets to decrease packet size

When there are some problems with *Path MTU discovery*,
you can mangle the TCP packets to decrease the *Maximum Segment Size*.

NOTE: This method should though not be a permanent fix due to the limitations to TCP and the necessity to use PMTUD in conjunction with IPv6.

```
*mangle
# 1250 needs to be confirmed, 1387 was too much
-A POSTROUTING -p tcp --tcp-flags SYN,RST SYN -o inet0 -j TCPMSS --set-mss 1250
COMMIT
```

## Examples

The following files will give you some examples of how to setup a useful configuration for `iptables`:

* [IPsec with VTI (IPv4)](../examples/iptables-vti-ipsec-full.ipv4)
* [IPsec with VTI (IPv6)](../examples/iptables-vti-ipsec-full.ipv6)
* [IPsec with VTI and BGP routing](../examples/iptables-bgp-gre-vti-ipsec-full.ipv4)
