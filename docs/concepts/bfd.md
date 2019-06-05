# Bidirectional Forwarding Detection (BFD)

Bidirectional Forwarding Detection is a protocol to test if a connection is
still active or if it is lost.
This is very useful in case of Ethernet links as well as for longer IP paths
in case of MPLS.

BFD is a lightweight protocol and can be used in different modes for checking
if the connection is still up.
For our usecase though, the *asynchronous mode*, where both sides send `Hello`
packets will be preferred.

The benefit of using BFD for link detection additionally to the keepalive part
of the routing protocol, like BGP, is, that the timeouts are tremendously
lower and therefore the switch to a healty route can be much faster.

Where the timeout of common BGP sessions can be in the range of 240s and might
be reduced to 30s, the BFD timeouts can be in the ranges of `<1s`.

Therefore it is advised to switch on BFD for link detection whereever
possible.
