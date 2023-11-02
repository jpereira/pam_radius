# Author: Jorge Pereira <jorge@freeradius.org>

ARG TAG=9
FROM --platform=linux/x86_64 rockylinux/rockylinux:$TAG

ENV CI_TEST_USER=tapioca
ENV CI_TEST_PASS=queijo

#
#  Install devtools like make and git and the EPEL
#
RUN yum update -y
RUN yum install -y \
    epel-release \
    git \
    openssl \
    rpmdevtools \
    rsync \
    wget \
    yum-utils \
#  which is required by fixture setup utilities
    which \
#  For debugging (e.g. in crossbuild)
    gdb \
    less \
    vim

# Enable PowerTools / CRB
#RUN yum install -y yum-utils dnf-plugins-core
RUN yum install -y yum-utils
RUN yum config-manager --enable PowerTools || :
RUN yum config-manager --enable powertools || :
RUN yum config-manager --enable crb || :

#  EPEL repository for freetds and hiredis
RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
    && yum install -y dnf-utils \
    && yum config-manager --enable epel-testing

# Set up NetworkRADIUS extras repository
#RUN echo '[networkradius-extras]'                                                   >  /etc/yum.repos.d/networkradius-extras.repo
#RUN echo 'name=NetworkRADIUS-extras-$releasever'                                    >> /etc/yum.repos.d/networkradius-extras.repo
#RUN echo 'baseurl=http://packages.networkradius.com/extras/centos/$releasever/'     >> /etc/yum.repos.d/networkradius-extras.repo
#RUN echo 'enabled=1'                                                                >> /etc/yum.repos.d/networkradius-extras.repo
#RUN echo 'gpgcheck=1'                                                               >> /etc/yum.repos.d/networkradius-extras.repo
#RUN echo 'gpgkey=https://packages.networkradius.com/pgp/packages@networkradius.com' >> /etc/yum.repos.d/networkradius-extras.repo
#RUN rpm --import https://packages.networkradius.com/pgp/packages@networkradius.com

# Install common tools
RUN yum install -y \
      yum-utils \
      bzip2 \
      gcc \
      hostname \
      make \
      perl \
      procps-ng \
      rpm-build \
      psmisc \
      sudo \
      screen

# Clome
RUN mkdir -p /opt/src/pam_radius.git && \
    git clone https://github.com/FreeRADIUS/pam_radius /opt/src/pam_radius.git
RUN wget https://raw.githubusercontent.com/jpereira/dotfiles/master/dot.screenrc -O .screenrc

WORKDIR /opt/src/pam_radius.git
RUN yum-builddep -y redhat/pam_radius_auth.spec
RUN make rpm
RUN rpm -ivh rpmbuild/RPMS/x86_64/pam_radius_auth*.rpm

# Test env
RUN sudo yum -y install \
                freeradius freeradius-utils \
                syslog-ng \
                openssh-server sshpass
# do the tests
RUN sudo useradd -d /tmp ${CI_TEST_USER}
RUN id ${CI_TEST_USER}

RUN ( sudo rm -f /var/log/secure && \
          sudo touch /var/log/secure && \
          sudo chmod 600 /var/log/secure )
RUN sudo killall -q -9 syslog-ng radiusd sshd || :
# https://stackoverflow.com/questions/47973554/how-to-let-syslog-workable-in-docker
RUN sudo sed -i 's/system()/# system()/g' /etc/syslog-ng/syslog-ng.conf
#RUN sudo /usr/sbin/syslog-ng --no-caps

RUN CI_TEST_USER="$CI_TEST_USER" CI_TEST_PASS="$CI_TEST_PASS"; \
    for i in setup-pam_radius.sh setup-freeradius.sh setup-sshd.sh; do \
        script="${PWD}/scripts/ci/$i"; \
        echo "Calling $script"; \
        sudo -E $script; \
    done

RUN echo | sudo ssh-keygen -A
RUN sudo /usr/sbin/sshd
RUN sudo rm -f /run/nologin # Needed to enable the log in!

RUN ( sudo make -C /etc/raddb/certs/ destroycerts all && \
      sudo sed 's/dh_file =/#dh_file =/g' -i /etc/raddb/mods-available/eap && \
      sudo chmod 0644 /etc/raddb/certs/server.pem )
#RUN sudo /usr/sbin/radiusd

RUN echo -e '#!/bin/bash\n(sudo /usr/sbin/syslog-ng --no-caps && \
    sudo /usr/sbin/sshd && \
    sudo /usr/sbin/radiusd && /bin/bash)' > /tmp/run.sh && chmod +x /tmp/run.sh

RUN cat /tmp/run.sh

ENTRYPOINT [ "/tmp/run.sh" ]
