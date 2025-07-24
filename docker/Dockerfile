FROM debian:trixie
LABEL authors="Rob Thomas <xrobau@gmail.com>"

ENV DEBIAN_FRONTEND noninteractive
RUN echo "dash dash/sh boolean false" | debconf-set-selections &&  dpkg-reconfigure dash
COPY 01-apt-norecommends /etc/apt/apt.conf.d/01norecommends

RUN apt-get update && apt-get install -y dialog apt-utils locales

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && locale-gen
ENV LANG en_US.utf8

RUN apt-get update && apt-get install -y \
      vim vim-autopep8 nano git curl sudo mc \
      build-essential pbuilder devscripts squashfs-tools \
      genisoimage lsb-release fakechroot libtool libapt-pkg-dev \
      quilt python3-lxml python3-setuptools \
      python3-coverage python3-sphinx python3-pystache python3-git \
      python3-pip python3-psutil python3-flake8 python3-autopep8 \
      flake8 pkg-config debhelper gosu po4a openssh-client jq unzip \
      syslinux grub2 figlet toilet

RUN apt-get update && apt-get install -y reprepro

# These are created by the Makefile
COPY repo-signing-key-fingerprint repo-signing-key /etc
RUN gpg --import /etc/repo-signing-key
# Set it as ultimately trusted
RUN echo "$(cat /etc/repo-signing-key-fingerprint):6:" | gpg --import-ownertrust


