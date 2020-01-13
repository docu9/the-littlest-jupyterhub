# Systemd inside a Docker container, for CI only
FROM ubuntu:18.04

RUN apt-get update --yes

RUN apt-get install --yes systemd curl git sudo

# Kill all the things we don't need
RUN find /etc/systemd/system \
    /lib/systemd/system \
    -path '*.wants/*' \
    -not -name '*journald*' \
    -not -name '*systemd-tmpfiles*' \
    -not -name '*systemd-user-sessions*' \
    -exec rm \{} \;

RUN mkdir -p /etc/sudoers.d

RUN systemctl set-default multi-user.target

STOPSIGNAL SIGRTMIN+3

# Set up image to be useful out of the box for development & CI
ENV TLJH_BOOTSTRAP_DEV=yes
ENV TLJH_BOOTSTRAP_PIP_SPEC=/srv/src
ENV PATH=/opt/tljh/hub/bin:${PATH}

RUN apt-get install -y \
    software-properties-common

RUN  add-apt-repository universe

RUN  apt-get update -y 
RUN apt-get install -y  \
    python3 \
    python3-venv \
    python3-pip

ENV TLJH_INSTALL_PREFIX=/opt/tljh

RUN python3 -m venv $TLJH_INSTALL_PREFIX/hub

#RUN mkdir /data

#WORKDIR /data



RUN mkdir $TLJH_INSTALL_PREFIX/hub/etc

# setup pip
RUN echo "[global]\n\ttimeout = 60\n\tindex-url = https://nexus.o1.dc9.kr/repository/pypi/simple\n\tindex= https://nexus.o1.dc9.kr/repository/pypi\n" \
        >> /etc/pip.conf
RUN $TLJH_INSTALL_PREFIX/hub/bin/pip install wheel

# RUN curl https://repo.continuum.io/miniconda/Miniconda3-{}-Linux-x86_64.sh |bash
# COPY . /srv/src
RUN git clone https://github.com/docu9/the-littlest-jupyterhub.git  /srv/src

RUN $TLJH_INSTALL_PREFIX/hub/bin/pip \
    install \
    --upgrade --editable \
    /srv/src

RUN $TLJH_INSTALL_PREFIX/hub/bin/python3 \
    -m \
    tljh.installer \
    --admin admin

#RUN systemctl start traefik
#RUN systemctl start jupyterhub

# CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]
CMD ["/usr/sbin/init"]
# python3 /srv/src/bootstrap/bootstrap.py --admin admin