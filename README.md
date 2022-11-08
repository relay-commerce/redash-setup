# Setup script for Redash with Docker on Amazon Linux 2

This is a reference setup for Redash on a single Amazon Linux 2 server, which uses Docker and Docker Compose for deployment.

This setup assumes you already have a PostgreSQL server running with a database and user set up for Redash.

## Provisioning a new server

1. Spin up a new EC2 instance with the following settings:
    1. Latest Amazon Linux 2 x86_64 AMI
    2. Instance type with at least 4GB RAM
    3. Publicly accessible

2. Log into the instance and run the following:

    ```sh
    $ sudo yum update
    $ sudo yum install git
    $ git clone https://github.com/sales-pop/redash-setup.git
    $ cd redash-setup && ./install_dependencies.sh
    ```

3. Log out and back in so the user has access to docker. Then run:

    ```sh
    $ cd redash-setup && ./setup.sh
    ```

4. Redash is up and running and accessible through the instance's public IP address.
