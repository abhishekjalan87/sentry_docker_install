#!/bin/bash
export PATH=/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin
docker run -d --name sentry-redis redis && \
docker run -d --name sentry-postgres --env-file env/.envpostgres -v /root/container-backup/sentry/postgress:/var/lib/postgresql/data postgres && \
secret_key=$(docker run --rm sentry config generate-secret-key) && \
docker volume create --driver local --opt type=none --opt device=/root/container-backup/sentry/config --opt o=bind sentry-config
docker run -it --rm -e SENTRY_SECRET_KEY=${secret_key} -p 9000:9000 --link sentry-postgres:postgres --link sentry-redis:redis sentry upgrade && \
docker run -d --name sentry -e SENTRY_SECRET_KEY=${secret_key} --env-file env/.envsentry -p 9000:9000 -v sentry-config:/etc/sentry -v /root/container-backup/sentry/files:/var/lib/sentry --link sentry-redis:redis --link sentry-postgres:postgres sentry && \
docker run -d --name sentry-cron -e SENTRY_SECRET_KEY=$secret_key --env-file env/.envsentry -v sentry-config:/etc/sentry -v /root/container-backup/sentry/files:/var/lib/sentry --link sentry-postgres:postgres --link sentry-redis:redis sentry run cron && \
docker run -d --name sentry-worker-1 -e SENTRY_SECRET_KEY=${secret_key} --env-file env/.envsentry -v sentry-config:/etc/sentry -v /root/container-backup/sentry/files:/var/lib/sentry --link sentry-postgres:postgres --link sentry-redis:redis sentry run worker
docker run -p 8000:80 --name pgadmin --env-file env/.envpgadmin -d pgadmin
docker run -p 443:443 --name nginx -v $(pwd)/nginx/nginx.conf:/etc/nginx/nginx.conf -v $(pwd)/ssl:/etc/nginx/ssl -d nginx