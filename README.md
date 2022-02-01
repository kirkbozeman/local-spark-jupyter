
This repo contains a WIP docker image to run Spark locally.

Useful docker commands:

```
docker build -t local-spark:latest .
docker run -it -p 8890:8890 -v ~:/mnt/local local-spark:latest
docker exec -it $(docker ps -q --filter ancestor=local-spark:latest) /bin/bash
docker stop $(docker ps -q --filter ancestor=local-spark:latest)
```

Or just use:

```
docker-compose up
```