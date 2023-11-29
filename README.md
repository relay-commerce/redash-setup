# Setup script for Redash with Docker on Amazon Linux 2

This is a reference setup for Redash on a single Amazon Linux 2 server, which uses Docker and Docker Compose for deployment.

This setup assumes you already have a PostgreSQL server running with a database
and user set up for Redash. If you don't see [Provisioning a new PostgreSQL
server](#provisioning-a-new-postgresql-server)

## Provisioning a new server

#### Create a new security group for the EC2 instance

- Name: redash
- Description: Manage access to Redash service
- Inbound rules: allow traffic on ports 22, 80, 443 from 0.0.0.0/0

#### Spin up a new EC2 instance

- Name: redash
- Latest Amazon Linux 2 x86_64 AMI
- Instance type with at least 4GB RAM (t3.medium)
- Storage: 8GB gp3 encrypted volume
- Security group: redash
- Publicly accessible

#### Set up a redash subdomain (e.g. redash.example.com)

1. Allocate a new Elastic IP address and associate it with the EC2 instance.
2. Add an A record pointing the redash subdomain to the instance's Elastic IP address.

Note: if done through a CDN (e.g. Cloudflare), don't enable proxy.

#### Set up Redash

1. Log into the instance and run the following:

    ```sh
    $ sudo yum update
    $ sudo yum install git
    $ git clone https://github.com/sales-pop/redash-setup.git
    $ cd redash-setup && ./setup.sh install_dependencies install_docker
    ```

2. Log out and back in so the user has access to docker. Then run:

    ```sh
    $ cd redash-setup && ./setup.sh create_directories create_env_file setup_nginx start_app
    ```

4. Redash is now up and running and accessible through the subdomain created earlier.

## Configure HTTPS

#### Generate the SSL certificates via Let's Encrypt

```sh
$ docker run -it --rm \
      -v /opt/redash/nginx/certs:/etc/letsencrypt \
      -v /opt/redash/nginx/certs-data:/data/letsencrypt \
      certbot/certbot certonly --webroot --webroot-path=/data/letsencrypt -d redash.example.com
```

#### Reconfigure NGINX to listen on HTTPS with the new SSL certificates

```sh
$ cd redash-setup && ./setup.sh setup_nginx
$ docker-compose -f data/docker-compose.yml restart nginx
```

#### How to renew the certificate (expires every 4 months)
To renew certificate just run `ssl_certificate_renew.sh` placed in `data` folder.

Before you run it please ensure that docker-compose.yml is accessible via `/home/ec2-user/redash-setup/data/docker-compose.yml` path 
or change `/home/ec2-user/redash-setup/data/docker-compose.yml` inside `ssl_certificate_renew.sh` to path to Redash compose file.

```sh
$ ./data/ssl_certificate_renew.sh
```

#### Automatic certificate renew
It is needed to add `crontab` entry to automatically renew certificate.

To do it run crontab editor
```sh
$ EDITOR=nano crontab -e 
```

Then add the following entry to it. Note that you should ensure that `/home/ec2-user/redash-setup/data/docker-compose.yml` is correct path to your compose file.
```
# Automatically try to renew Redash SSL certificate every month on day-of-month 15.
0 3 15 * * /home/ec2-user/redash-setup/data/ssl_certificate_renew.sh
```

Also don't forget to check that cron process is running:
```sh
$ service crond status
```

## Setup Docker log rotation
There could be a situation where containers are up and running for a long time 
and the Docker log files grow to a large size.

Check current logs size for Docker containers.
```sh
sudo du -h $(docker inspect --format='{{.LogPath}}' $(docker ps -qa))
```

Docker log rotation could be configured to avoid a situation when Docker uses too much disk space.

1. Create `daemon.json` for docker configuration.
```sh
sudo touch /etc/docker/daemon.json
```
2. Start to edit it.
```sh
sudo nano /etc/docker/daemon.json
```
3. Put the following content in it.Note that you can use any `max-size` and `max-file` values depending on your needs.
```json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "20m",
    "max-file": "5"
  }
}
```
4. Save file and restart Docker service.
```sh
sudo systemctl restart docker
```
5. Log rotation will be applied only to new containers so we need to restart existing containers.
```sh
docker-compose -f data/docker-compose.yml down --remove-orphans
docker-compose -f data/docker-compose.yml up -d
```
6. Profit!

## Set up Google OAuth

1. Follow https://redash.io/help/open-source/setup#Google-OAuth-Setup
2. Add Google's client ID and secret to the .env file.

## Create a read-only user to connect a DB as a data source

### PostgreSQL

```sql
CREATE USER redash WITH ENCRYPTED PASSWORD '<strong_password>';
GRANT USAGE ON SCHEMA public TO redash;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO redash;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO redash;
```

### MySQL

```sql
CREATE USER 'redash'@'%.ec2.internal' IDENTIFIED BY '<strong_password>';
GRANT SELECT, SHOW VIEW ON dbname.* TO 'redash'@'%.ec2.internal';
FLUSH PRIVILEGES;
```

## Provisioning a new PostgreSQL server

#### Create a new security group for the RDS instance

- Name: rds-redash
- Description: Manage access to Redash RDS instance
- Inbound rules: allow traffic on port 5432 from the `redash` security group

#### Spin up a new RDS instance

- Name: redash
- Engine: PostgreSQL 13.x
- Instance type: t4g.micro
- Single DB
- Master username: <random 6 char string>
- Master password: <random 24 char string>
- Storage: 20GB gp3 encrypted volume; no autoscaling
- Network:
    - Don’t connect to an EC2 compute resource
    - Public access: No
    - Security group: rds-redash
- Performance insights: no
- Backup:
    - Automated backups: enabled
    - Backup retention period: 14 days

#### Create a database and user for Redash

Log into Postgres and run:

```sql
CREATE DATABASE redash_production;
CREATE USER redash WITH ENCRYPTED PASSWORD '<random_24_char_string>';
GRANT ALL PRIVILEGES ON DATABASE redash_production TO redash;
```

Note: You might need to temporarily add your IP address to the security group
or use a tunnel via the `redash` EC2 instance.


