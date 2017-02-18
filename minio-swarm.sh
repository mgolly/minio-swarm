#!/usr/bin/env sh

openssl rand -hex 10 > .minio_access_key
docker secret create MINIO_ACCESS_KEY .minio_access_key

openssl rand -hex 15 > .minio_secret_key
docker secret create MINIO_SECRET_KEY .minio_secret_key

docker network create --driver overlay minio

docker service create --name minio --network minio \
  --replicas 4 --publish 9000:9000 \
  --secret MINIO_ACCESS_KEY --secret MINIO_SECRET_KEY \
  --env REPLICAS=4 \
  simonpure/minio

