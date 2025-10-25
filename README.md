## slurm with docker an easy start guide

this repository is aimed to learn how slurm works in terms of job submitting and queueing in a containerized environment.

#### install dependencies

- Docker
- Docker Compose

###### generate secrets

```bash
#in the project root directory (/slurm-docker)
mkdir secrets
dd if=/dev/urandom bs=1 count=1024 of=secrets/munge.key
chmod 400 secrets/munge.key
```
###### build the containers

```bash
#in the project root directory (/slurm-docker)
docker build -t slurm-base:latest ./base
docker compose build
docker compose up -d
```