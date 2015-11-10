# Copyright (C) 2015 zulily, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This is a Dockerfile for creating a ubuntu image with init, systemd and a masterless salt-minion
# Please see README.md for more information.

# Make sure to specify the Ubuntu base image here and to set the version for the
# UBUNTU_VERSION variable below
FROM ubuntu:15.10
MAINTAINER zulily

# Miscellaneous Settings
ENV UBUNTU_VERSION "15.10"
ENV SALT_VERSION "2015.8.1"
ENV TERM="vt100" XDG_RUNTIME_DIR="/run/user/$(id -u)"

LABEL ubuntu_version=$UBUNTU_VERSION
LABEL salt_version=$SALT_VERSION
LABEL masterless="true"


# Add some files we'll need for package installation
ADD files/sources.list /etc/apt/sources.list
ADD files/resolv.conf /etc/resolv.conf

# Update package lists
RUN apt-get update

# Install a few packages to get started, but leave package installation up to salt in general
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y apt-utils vim bind9-host wget iputils-ping software-properties-common

RUN mkdir -p /etc/salt/minion.d && \
    chmod -R 755 /etc/salt

ADD files/10-minion-overrides.conf /etc/salt/minion.d/

# No agetty
RUN rm -f /etc/init/tty*
RUN rm -f /etc/systemd/system/getty.target.wants/*

# Update the .bashrc so once attached, the salt-minion will start if it is not the case.
ADD files/bashrc_update.sh /root/
RUN chmod +x /root/bashrc_update.sh
RUN /root/bashrc_update.sh && rm -f /root/bashrc_update.sh

# Install salt from the official git repo, a tagged release
# The salt-minion will fail to start because systemd cannot be started...
# docker build does not support --privileged.  salt-minion does successfully install,
# so this error may be safely ignored.  An || /bin/true is specified to have a zero return code
RUN apt-get install wget -y && \
    wget -O install_salt.sh https://bootstrap.saltstack.com && \
    sh install_salt.sh -X -P git v$SALT_VERSION || \
    /bin/true

CMD [ "/sbin/init" ]
