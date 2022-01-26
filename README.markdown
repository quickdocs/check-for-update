# quickdocs/check-for-update

Docker image to check if new Quicklisp dist update exists.  
If found a new one, it creates a new GitHub deployment to invoke the Quickdocs update process.

* [quickdocs/check-for-update](https://hub.docker.com/r/quickdocs/check-for-update)

## Usage

It runs a script in a Docker container and quit.

```
$ docker run --rm -it -e GITHUB_TOKEN=xxxxxxxxxxxxxxxx quickdocs/check-for-update
```

This image is meant to be executed periodically with [swarm-cronjob](https://github.com/crazy-max/swarm-cronjob).

```
$ docker service create --name swarm-cronjob \
  --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
  --env "LOG_LEVEL=info" \
  --env "LOG_JSON=false" \
  --constraint "node.role == manager" \
  crazymax/swarm-cronjob

$ docker service create --name quickdocs-check-for-update \
  --restart-condition none \
  --replicas 0 \
  --label swarm.cronjob.enable=true \
  --label "swarm.cronjob.schedule=* */1 * * *" \
  --label swarm.cronjob.skip-running=false \
  -e GITHUB_TOKEN=xxxxxxxxx \
  quickdocs/check-for-update
```
