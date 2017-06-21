# RPM Spec for Consul Template

Originally forked from [CiscoCloud/consul-template-rpm](https://github.com/CiscoCloud/consul-template-rpm) and modified for the ENA environment.

# Building

The RPMs may be built with [Docker](#with-docker), [Vagrant](#with-vagrant), or [manual](#manual).

Whatever way you choose you will need to do a few basic things first.

```bash
git clone https://github.com/myENA/consul-template-rpm  ## check out this code
cd consul-template-rpm                                  ## uhh... you should know
mkdir -p artifacts                                      ## prep the artifacts location
```

## With Docker

```bash
docker build -t ena/consul-template-rpm .                                ## build the image
docker run -v $PWD/artifacts:/tmp/artifacts -it ena/consul-template-rpm  ## run the image and build the RPMs
```

## With Vagrant

```bash
vagrant box add centos/7           ## add the official CentOS 7 box
vagrant box update --box centos/7  ## or update if you already have it
vagrant up                         ## provision and build the RPMs
```

## Manual

```bash
cat build.sh     ## read the script
```

## Result

Two RPMs will be copied to the `artifacts` folder:
1. `consul-template-<version>-<release>.rpm`          - The binary and systemd service definition (required)
2. `consul-template-config-<version>-<release>.rpm`   - Example agent configuration (recommended)

# Running

1. Install the RPM(s) that you need
2. Review and edit (if needed) `/etc/sysconfig/consul-tempalte` and associated config under `/etc/consul-template.d/*` (config package)
3. Start the service and tail the logs: `systemctl start consul-template` and `journalctl -f --no-pager -u consul-template`
4. Optionally start on reboot with: `systemctl enable consul-template`

## Configuring

Config files are loaded in lexicographical order from the `config` specified in `/etc/sysconfig/consul-template` (config package).
You may modify and/or add to the provided configuration as needed.

# Further reading

See the [consul.io](http://www.consul.io) website.
