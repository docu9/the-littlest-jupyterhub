#!/bin/bash
docker run \
  --rm \
  --privileged \
  --name=tljh-dev \
  --publish 12000:80 \
  -v $(pwd):/srv/src \
  tljh-systemd
