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

TODO: how to auto renew cert because it expires after 4 months

## Set up Google OAuth

1. Follow https://redash.io/help/open-source/setup#Google-OAuth-Setup
2. Add Google's client ID and secret to the .env file.

## Create a read-only user to add PostgreSQL as a data source

```sql
CREATE USER redash WITH ENCRYPTED PASSWORD '<strong_password>';
GRANT USAGE ON SCHEMA public TO redash;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO redash;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO redash;
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


