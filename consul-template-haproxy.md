# Dynamic HAProxy

The entire HAProxy configuration is generated from a combination of KVPs and service registration data in the Consul cluster.

The first two sections are purely KV driven and build configuration based on the names and values of the keys as well as the folder structure to complete the “global” and “defaults” sections.  Configuration items that repeat but with different values (option, errorfile, stat, etc.) can be placed in a folder with the name of the option and then the key/value beneath represent the arguments to the config directive.

This key and value ...

    /lb/haproxy/defaults/option/forwardfor => except 127.0.0.0/8

Generates the following config ...

    option forwardfor except 127.0.0.0/8

The templating loops over all the bare keys first and then loops over keys in directories so you always get the bare keys listed first in the config and multi options are grouped together …

This key structure …

```
lb/
    haproxy/
        acl/
        defaults/
            errorfile/
                400                 => /usr/share/haproxy/400.http
                403                 => /usr/share/haproxy/403.http
                408                 => /usr/share/haproxy/408.http
                500                 => /usr/share/haproxy/500.http
                502                 => /usr/share/haproxy/502.http
                503                 => /usr/share/haproxy/503.http
                504                 => /usr/share/haproxy/504.http
            log                     => global
            maxcon                  => 2500
            option/
                allbackups
                dontlognull
                forwardfor          => except 127.0.0.0/8
                http-server-close
                httplog
                redispatch
            rawText
            retries                 => 3
            stats/
                auth                => xxxx:xxxx
                enable
                hide-version
                realm               => HAProxy\ Statistics
                scope               => .
                uri                 => /haproxy?stats
            timeout/
                check               => 10s
                client              => 5m
                connect             => 10s
                http-keep-alive     => 10s
                http-request        => 10s
                queue               => 1m
                server              => 5m
                tunnel              => 1h
        frontend/
            main/
                bind/
                    127.0.0.1:80
                    127.0.0.1:443   => ssl crt /etc/pki/tls/certs/snakeoil-combined.pem
                mode                => http
                rawText
        global/
            chroot                  => /var/lib/haproxy
            group                   => haproxy
            log                     => 127.0.0.1 local2
            maxconn                 => 4000
            pidfile                 => /var/run/haproxy.pid
            stats/
                socket              => /var/lib/haproxy/stats
            user                    => haproxy
        misc/
```

Generates …

```
## lb/haproxy/global
global
    chroot /var/lib/haproxy
    group haproxy
    log 127.0.0.1 local2
    maxconn 4000
    pidfile /var/run/haproxy.pid
    user haproxy
    stats socket /var/lib/haproxy/stats

## lb/haproxy/defaults
defaults
    log global
    maxconn 2500
    retries 3
    errorfile 400 /usr/share/haproxy/400.http
    errorfile 403 /usr/share/haproxy/403.http
    errorfile 408 /usr/share/haproxy/408.http
    errorfile 500 /usr/share/haproxy/500.http
    errorfile 502 /usr/share/haproxy/502.http
    errorfile 503 /usr/share/haproxy/503.http
    errorfile 504 /usr/share/haproxy/504.http
    option allbackups
    option dontlognull
    option forwardfor except 127.0.0.0/8
    option http-server-close
    option httplog
    option redispatch
    stats auth xxxx:xxxx
    stats enable
    stats hide-version
    stats realm HAProxy\ Statistics
    stats uri /haproxy?stats
    timeout check 10s
    timeout client 5m
    timeout connect 10s
    timeout http-keep-alive 10s
    timeout http-request 10s
    timeout queue 1m
    timeout server 5m
    timeout tunnel 1h

## lb/haproxy/frontend/main
frontend main
    mode http
    bind 127.0.0.1:80
    bind 127.0.0.1:443 ssl crt /etc/pki/tls/certs/snakeoil-combined.pem
```

## Note
Multi datacenter awareness is dependent on each linked consul datacenter having a `env/dc` key that matches the consul datacenter.

## Frontend vs. Backend services
Things get a little different when we move further into the frontend and backend sections of the configuration as they are almost completely service driven in nature.  I loop over the list of all registered services a few times before the template is fully generated in order to create each section.  The first loop over all the services occurs in the frontend section to generate all the path based acls to configure routing to the backends.

```
## end raw{{end}}{{end}}{{range services}}{{if service .Name}}{{if in .Tags "proxy-unique"}}{{range service .Name}}
## unique {{.ID}}
acl path_{{.ID}} path_beg /{{.ID}}/
use_backend app_{{.ID}} if path_{{.ID}}{{end}}{{end}}{{if in .Tags "proxy-standard"}}{{with index (service .Name) 0}}
## standard {{.Name}}
acl path_{{.Name}} path_beg /{{if in .Tags "proxy-dash2dots"}}{{.Name | split "-" | join "."}}{{else}}{{.Name}}{{end}}/
use_backend app_{{.Name}} if path_{{.Name}}{{end}}{{end}}{{end}}{{end}}
```

This block ranges over all the services checking if they are tagged either “proxy-unique” or “proxy-standard” and creates acls accordingly.  When a service is tagged “proxy-unique” it gets a 1:1 path to service provider translation based on the unique service id and the service address/port.  In contrast when a service is tagged “proxy-standard” it creates a single acl entry based on the service name and optionally converts dashes in that service name to dots to accommodate some of our legacy services because Consul doesn’t allow periods in service names.

Once all of the acls have been generated we once again loop over all of the services to generate the first backend which is the default backend that provides the proxy root.  This backend is statically named and simply loops over all services and adds any service tagged “proxy-root” to a  round-robin balanced backend.

Finally, we generate the backends referenced by the acl entries we created previously.  These also take into consideration the “proxy-unique”, “proxy-standard” and “proxy-dash2dots” tags in addition to two other tags that are only used in the backends.  To make sure a service is only available to requests sourced from within the network you can tag your service with “proxy-internal” which ensures an acl (lb/haproxy/misc/enaInternal) is added to the configuration block.  The last tag available is “proxy-nostrip” which controls weather or not we strip the namespace path off before sending it to the actual backend destination.

## Tag summary
| Tag                            | Description |
|--------------------------------|--------------
| proxy-unique                   | setup a 1:1 mapping between unique service IDs and the hosts that they provide
| proxy-standard                 | typical round-robin load balancing between the service name and all of the hosts providing that service
| proxy-root                     | directs haproxy that you are capable of handling requests for the default backend (root)
| proxy-nostrip                  | when specified the request to the proxy will be handed off to the backend service unmodified (the access path will not be removed)
| proxy-internal                 | places the contents of "lb/haproxy/misc/enaInternal" from the KV store into the backend section to prevent access from outside our network
| proxy-dash2dots                | replaces all "-" in a service name with "." before using the service name as a proxy path in the configuration ("ENA-API-Foo" becomes "ENA.API.Foo")
| proxy-proxy-rewrite-net-cookie | places the contents of "lb/haproxy/misc/rewriteNetCookie" from the KV store into the backend configuration |
| proxy-check                    | appends the haproxy "check" keyword to end of the "server" line
| proxy-ssl                      | appends "ssl verify none" to the end of the "server" line to allow ssl backends
| proxy-sticky-session           | adds a block to standard backends to create a "stick-table" that will stick source ips to a single backend for one hour

You must list at least one of proxy-root, proxy-standard or proxy-unique for the service to be exposed by haproxy and should probably not use both proxy-unique and proxy-standard on the same service.  The other tags may be combined as needed to achieve the desired result.
