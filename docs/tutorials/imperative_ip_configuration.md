# imperative IP configuration
This tutorial explains how to configure IP related entities like addresses, interfaces or tunnels
using a shell script.

This is the preferred way for setting up IP addresses, GRE tunnels, VTI devices, which will be explained in more details in later sections.

The initialisation script will run as the last init container, and therefore after VXLAN interfaces are attached to the pod.

<!-- toc -->

* [add IP address to an interface](#add-ip-address-to-an-interface)
  * [the first example](#the-first-example)
  * [the shell script itself](#the-shell-script-itself)
* [add route to an interface](#add-route-to-an-interface)

<!-- tocstop -->

## add IP address to an interface

To start with a simple example, we will add IP addresses to an interface,
which already exists in the pod on startup.

### the first example

This is an example of one simple configuration:

```yaml
initScript:
  enabled: true
  env:
    ADDITIONAL_IPV4_ADDRESS: 192.0.2.1
    ADDITIONAL_IPV4_CIDR: "24"
    
    ADDITIONAL_IPV6_ADDRESS: "2001:DB8::1"
    ADDITIONAL_IPV6_CIDR: "64"
    
    INTERFACE: eth0
  script: |
    set -xeu
    
    echo "set up additional IP address\n"
    ip addr add ${ADDITIONAL_IPV4_ADDRESS}/${ADDITIONAL_IPV4_CIDR} dev ${INTERFACE}
    ip -6 addr add ${ADDITIONAL_IPV6_ADDRESS}/${ADDITIONAL_IPV6_CIDR} dev ${INTERFACE}
```

In the second line, the module, to run an initialisation script on startup, is enabled.

After that under the `initScript.env` parameter, environmental variables can be set.
These can be used in the script itself.

It is highly recommended to make use of environmental variables for configuration data, as it makes it is easier to copy the script itself for multiple deployments.
Further, when one variable is used multiple times, the actual value just to be changed in one place.

### the shell script itself

As the `initScript.script` parameter, a shell script as a long block string will be provided.
The script has to be a POSIX shell script, as `bash` is not supported.
Additionally every program can be used, which is installed in the network tools container.

In this example, the first line sets the shell to output the commands, which are actually executed (`set -x`).
It also sets it to check, if all environmental variables are actually set and fail if this is not the case (`set -e`).
Last, the parameter is set to fail the whole script, if one of the commands fails and not continue with further settings (`set -u`).

After that, the actual shell script follows.
In this case a message is written to the output for debugging using the `echo` command.

In the second last line, the `ip` command is used to add the IPv4 address to the device.
This is the standard command used on modern linux distributions.

As seen in the last line, you have to add `-6` to most `ip` commands operating with IPv6 addresses.

## add route to an interface

In this second example, we will add static routes to an existing interface.

```yaml
initScript:
  enabled: true
  env:
    ROUTE_PREFIX: 192.0.2.32/27
    ROUTER: 192.0.2.2
    
    ROUTE_IPV6_PREFIX: 2001:DB8:1::/48
    ROUTER_IPV6: 2001:DB8::2
  script: |
    set -xeu
    
    echo "set up additional route\n"
    ip route add ${ROUTE_PREFIX} via ${ROUTER}
    ip -6 route add ${ROUTER_IPV6_PREFIX} via ${ROUTER_IPV6}
}
```

As seen in the example, the only difference are the last line in which `ip route` is used to add a route to the kernels routing table.

Like in the example above, `ip -6` has to be used, to add routes to the IPv6 routing table.
