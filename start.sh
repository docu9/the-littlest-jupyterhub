#!/bin/bash
NAME=tljh-dev
docker exec \
  -d ${NAME} \
  systemctl start jupyterhub