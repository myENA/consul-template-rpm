# RPM Spec and Build for Consul-Template

# Building

The RPMs may be built with [Docker](#with-docker), [Vagrant](#with-vagrant), or [manual](#manual).

Whatever way you choose you will need to do a few basic things first.

```bash
git clone https://github.com/myENA/consul-tempalte-rpm  ## check out this code
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
vagrant up                         ## provision and build the RPMs
```

## Manual

```bash
cat build.sh     ## read the script
```
## Result

Your RPMs and SRPMs will be copied to the `artifacts` folder.  Congratulations.  You just built RPMs in a controlled environment in an easily reproducible manner.
