FROM centos:7
MAINTAINER Aaron Hurt <ahurt@ena.com>

VOLUME ["/tmp/artifacts"]

ADD . /tmp/build

RUN yum -y install sudo
RUN sed -i.bak -n -e '/^Defaults.*requiretty/ { s/^/# /;};/^%wheel.*ALL$/ { s/^/# / ;} ;/^#.*wheel.*NOPASSWD/ { s/^#[ ]*//;};p' /etc/sudoers
RUN useradd -s /bin/bash -G adm,wheel,systemd-journal -m builder
RUN chown -R builder /home/builder

WORKDIR /home/builder
CMD /tmp/build/build.sh

USER builder
