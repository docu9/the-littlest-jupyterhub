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



#for theia 
RUN npm -g i yarn


COPY extra /srv/extra

WORKDIR /srv/extra

RUN yarn && yarn theia build
ENV THEIA_PATH=srv/extra



# RUN systemctl start traefik
#RUN systemctl start jupyterhub
# hub/bin 과 user/bin 의 차이가 있다.
# 여기서 부터
RUN sudo -E $TLJH_INSTALL_PREFIX/user/bin/pip install --upgrade jupyterlab
RUN sudo -E  $TLJH_INSTALL_PREFIX/user/bin/jupyter labextension update --all
RUN sudo -E $TLJH_INSTALL_PREFIX/user/bin/jupyter labextension install @jupyterlab/git
RUN sudo -E  $TLJH_INSTALL_PREFIX/user/bin/pip install jupyterlab_sql


#### 여기까지 동작하지 않는다.



# for jupyter server proxy  [ rstudio , theia, shiny]

RUN git clone https://github.com/docu9/jupyter-server-proxy.git /srv/jupyter-server-proxy
WORKDIR /srv/jupyter-server-proxy/jupyterlab-server-proxy
RUN  npm i && npm run build 
RUN $TLJH_INSTALL_PREFIX/user/bin/pip install /srv/jupyter-server-proxy
#RUN $TLJH_INSTALL_PREFIX/user/bin/jupyter install @jupyterlab/server-proxy
RUN sudo -E $TLJH_INSTALL_PREFIX/user/bin/jupyter lab build 
RUN $TLJH_INSTALL_PREFIX/user/bin/jupyter serverextension enable --sys-prefix jupyter_server_proxy
# CMD ["/sbin/init && systemctl jupyterhub"]
# python3 /srv/src/bootstrap/bootstrap.py --admin admin

CMD ["/bin/bash", "-c", "exec /sbin/init --log-target=journal 3>&1"]