# configure IPs and interfaces declaratively

There are two different ways in CGW to add IP addresses and interfaces, a declarative and an imperative one.
This tutorial will describe how to add IP addresses declarative using a yaml configuration.

To learn, how to use a shell script to configure IP settings, see [imperative IP configuration](./imperative_ip_configuration.md).

This tutorial will result in a part of a configuration, you can use in your deployment.
To learn how to deploy CGW, please refer to the [General Usage Guide](./general_usage.md)

<!-- toc -->

* [Enable the module](#enable-the-module)
* [defining actions on interfaces](#defining-actions-on-interfaces)
  * [type `ip`](#type-ip)
  * [type `bridge`](#type-bridge)
  * [type `interface`](#type-interface)
* [define static routes](#define-static-routes)

<!-- tocstop -->

## Enable the module

To enable the declaritive configuration of IP addresses, you first have to enable the module itself:

```
ipSetup:
  enable: true # the default is false
```

## defining actions on interfaces

As of writing, there are two different kinds of configuration you can add.
The first is configuring interfaces and the second is configuring routes.

All interfaces, which are used by the configuration have to exist before this step is executed (see [order of configuration]().

This example shows the possible configurations:

```
ipSetup:
  ip:
  - interface: vxeth1
    addr: "192.0.2.1/24"
    type: ip
  - interface: bridge0
    type: bridge
    bind:
      - gre9
      - vxeth0
  - interface: gre9
    type: interface
    action: up
```

As seen, the node `ipSetup.ip` is a list ip configurations.

Every item has to contain an `interface` value, which defines on which interface the
configuration will be applied.

The second mandatory field in the item is `type`.
At the moment there are three types available:

* `ip`
* `bridge`
* `interface`

### type `ip`

The type `ip` adds an IPv4 address to an interface.

The field `addr` has to contain an IP address followed by the netmask in the `/` notation.

### type `bridge`

The type `bridge` creates a new bridge interface.

The node `bind` is a list of names of interfaces, which will be connected to the bridge.
The bridge will automatically be enabled.

### type `interface`

The type `interface` executes actions on the interface.

The field `action` can either be `up` or `down`.
This will set the interface either in the up or down state.

## define static routes

Static routes can be added by elements under the list `ipSetup.staticRoutes`.

They have to follow the semantic of the `ip` tool on Linux, beeing `ip route add <list element>`.

The following example adds two static routes over the same gateway:

```
ipSetup:
  staticRoutes:
  - "203.0.113.15 via 192.0.2.1" 
  - "203.0.113.16 via 192.0.2.1"
```
