#!/usr/bin/env bash
set -ex  ## we like things verbose
## install helpful tools
sudo yum install -y rpmdevtools rpm-devel rpm-build mock
## setup our build path
rpmdev-setuptree
## link the specs
ln -sf /tmp/build/SPECS/consul-template.spec $HOME/rpmbuild/SPECS/
## link the sources
find /tmp/build/SOURCES -type f -exec ln -sf {} $HOME/rpmbuild/SOURCES/ \;
## download sources
spectool -g -R $HOME/rpmbuild/SPECS/consul-template.spec
## build our packages
rpmbuild -ba $HOME/rpmbuild/SPECS/consul-template.spec
## copy built files out of the vagrant/docker environment
## skip if you are doing this manually
if [ -f /.dockerenv ] || [ -f /.doing_the_vagrant ]; then
    sudo cp -f $HOME/rpmbuild/RPMS/x86_64/consul-template*.rpm /tmp/artifacts/
fi
