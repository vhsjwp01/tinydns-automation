# DNS repo - An R&D project for evaluating the use of Stash/Bamboo/mcollective to manage DNS services
## DNS File Format (TinyDNS notation)
### A, NS record combined
`&fqdn:ip:x:ttl:timestamp:lo`

Creates an A and NS record. Typically used to delegate a subdomain; can be used in combination with Z to accomplish the same thing as the combo above, but with a different email address.

**&my.example.net:208.210.221.65:something:
### A and PTR Record
`=fqdn:ip:ttl:timestamp:lo`

**=alpha.my.example.net:192.168.1.1**

### A Record
`+fqdn:ip:ttl:timestamp:lo`

**+alpha.my.example.net:192.168.1.1**

### MX Record
`@fqdn:ip:x:dist:ttl:timestamp:lo`

**@my.example.net:208.210.221.77:something**

### CNAME Record
`Cfqdn:x:ttl:timestamp:lo`

**Cmailserver.my.example.net:yourmailserver.somewhere.com**

### TXT Record
`'fqdn:s:ttl:timestamp:lo`

**my.example.net:Please do not bug us we know our DNS is broken**

### SRV Record
Sfqdn:ip:x:port:priority:weight:ttl:timestamp

Standard rules for ip, x, ttl, and timestamp apply. Port, priority, and weight all range from 0-65535. Priority and weight are optional; they default to zero if not provided.

**Sconsole.zoinks.example.com:1.2.3.4:rack102-con1:2001:7:69:300:**

###NAPTR Record
`Nfqdn:order:pref:flags:service:regexp:replacement:ttl:timestamp`

The same standard rules for ttl and timestamp apply. Order and preference (optional) range from 0-65535, and they default to zero if not provided. Flags, service and replacement are character-strings. The replacement is a fqdn that defaults to '.' if not provided.

**Nsomedomain.org:100:90:s:SIP+D2U::_sip._udp.somedomain.org**

### AAAA Record
`:fqdn:28:location:ttl`

These records are used to resolve IPv6 addresses.

**:alpha.my.example.net:28:\050\001\103\000\302\072\000\077\105\052\064\355\256\064\063\124:86400**
