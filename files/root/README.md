# vpnhub

## geoipsets

to download geoip database: ```systemctl start update-geoipsets```
to enable geoip periodic update: ```systemctl enable update-geoipsets.timer --now```

nftables rules will be reloaded by ```systemctl start nftables-load``` everytime update is done.

## nftables

example /var/lib/nftables/rules-save:

```
#!/usr/bin/nft -f
flush ruleset

#include "/var/lib/geoipsets/dbip/nftset/ipv4/JP.ipv4"
#include "/var/lib/geoipsets/dbip/nftset/ipv6/JP.ipv6"

table inet filter {
    set trusted_sources4 {
        type ipv4_addr;
        flags interval;
        elements = {
            127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16
        };
    }

    set trusted_sources6 {
        type ipv6_addr;
        flags interval;
        elements = {
            ::1, fe80::/10, fc00::/7
        };
    }

    chain input {
        type filter hook input priority 0; policy drop;

        ct state { established, related } accept

        icmpv6 type { packet-too-big, nd-neighbor-solicit, nd-neighbor-advert, nd-router-solicit, nd-router-advert } accept
        ip protocol icmp icmp type != echo-request accept

        udp dport { 51820, 51821, 51823 } accept

        ip saddr @trusted_sources4 accept
        ip6 saddr @trusted_sources6 accept

        #ip saddr != $JP.ipv4 drop
        #ip6 saddr != $JP.ipv6 drop

        tcp dport { 80, 443, 22 } accept
    }
}

table inet routing {
    chain input {
        type filter hook input priority 10; policy accept;
        iifname "wg0" tcp flags syn / syn,rst tcp option maxseg size 1025-1536 tcp option maxseg size set 1024
    }
    chain forward {
        type filter hook forward priority 0; policy accept;
        iifname "wg0" tcp flags syn / syn,rst tcp option maxseg size 1025-1536 tcp option maxseg size set 1024
    }
    chain prerouting {
        type nat hook prerouting priority -100; policy accept;
        udp dport { 51821, 51822 } dnat to :51820
    }
    chain postrouting {
        type nat hook postrouting priority 100; policy accept;
        ip saddr 192.168.0.0/16 oifname "eth0" masquerade
        ip6 saddr fc00::/7 oifname "eth0" masquerade
    }
}
```

