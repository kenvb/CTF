BACnet/IP is standardized to use UDP port 47808 (0xBAC0 in hexadecimal) for its communication. This port is the default for both transmitting and receiving BACnet messages over IP networks, although some implementations might allow configuration of alternative ports if necessary.
```
nmap --script bacnet-info -sU -p 47808 <host>
```