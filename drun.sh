#!/bin/bash
docker run \
  --rm \
  --privileged \
  --name=tljh-dev \
  --publish 12000:80 \
  --publish 3000:3000 \
  -v $(pwd):/srv/src \
  tljh-systemd
