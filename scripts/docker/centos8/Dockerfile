ARG TAG=stream
FROM --platform=linux/x86_64 quay.io/centos/centos:$TAG

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

# Extra repos for CentOS and Rocky Linux 8
RUN echo '[ltb-project]'                                              >  /etc/yum.repos.d/ltb-project.repo
RUN echo 'name=LTB project packages'                                  >> /etc/yum.repos.d/ltb-project.repo
RUN echo 'baseurl=https://ltb-project.org/rpm/$releasever/$basearch'  >> /etc/yum.repos.d/ltb-project.repo
RUN echo 'enabled=1'                                                  >> /etc/yum.repos.d/ltb-project.repo
RUN echo 'gpgcheck=1'                                                 >> /etc/yum.repos.d/ltb-project.repo
RUN echo 'gpgkey=https://www.ltb-project.org/documentation/_static/RPM-GPG-KEY-LTB-project' >> /etc/yum.repos.d/ltb-project.repo
RUN rpm --import https://www.ltb-project.org/documentation/_static/RPM-GPG-KEY-LTB-project
RUN yum install -y epel-release

# Enable PowerTools / CRB
RUN yum install -y yum-utils dnf-plugins-core
RUN yum config-manager --enable PowerTools || :
RUN yum config-manager --enable powertools || :
RUN yum config-manager --enable crb || :

# Enable EPEL for Rocky Linux 9
# RUN yum install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm

# Set up NetworkRADIUS extras repository
RUN echo '[networkradius-extras]'                                                   >  /etc/yum.repos.d/networkradius-extras.repo
RUN echo 'name=NetworkRADIUS-extras-$releasever'                                    >> /etc/yum.repos.d/networkradius-extras.repo
RUN echo 'baseurl=http://packages.networkradius.com/extras/centos/$releasever/'     >> /etc/yum.repos.d/networkradius-extras.repo
RUN echo 'enabled=1'                                                                >> /etc/yum.repos.d/networkradius-extras.repo
RUN echo 'gpgcheck=1'                                                               >> /etc/yum.repos.d/networkradius-extras.repo
RUN echo 'gpgkey=https://packages.networkradius.com/pgp/packages@networkradius.com' >> /etc/yum.repos.d/networkradius-extras.repo
RUN rpm --import https://packages.networkradius.com/pgp/packages@networkradius.com

# Install common tools
RUN yum install -y rpm-build make gcc perl git-core

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
      sudo

# Clome
RUN mkdir -p /opt/src/pam_radius.git && \
    git clone https://github.com/jpereira/pam_radius /opt/src/pam_radius.git

WORKDIR /opt/src/pam_radius.git
RUN yum-builddep -y redhat/pam_radius_auth.spec
RUN make rpm
RUN rpm -ivh rpmbuild/RPMS/x86_64/pam_radius_auth*.rpm

# do the tests
