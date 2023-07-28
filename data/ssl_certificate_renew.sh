#!/bin/sh

docker run -t --rm \
      -v /opt/redash/nginx/certs:/etc/letsencrypt \
      -v /opt/redash/nginx/certs-data:/data/letsencrypt \
      certbot/certbot renew --webroot --webroot-path=/data/letsencrypt

# Ensure that docker-compose.yml is accessible via `/home/ec2-user/redash-setup/data/docker-compose.yml` path
# or change `/home/ec2-user/redash-setup/data/docker-compose.yml` to path to Redash compose file.
# Also please ensure that `/usr/local/bin/docker-compose` is path to docker-compose binary.
/usr/local/bin/docker-compose -f /home/ec2-user/redash-setup/data/docker-compose.yml exec nginx nginx -s reload
