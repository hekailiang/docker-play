docker-ip() {
  boot2docker ip 2> /dev/null
}

docker-enter() {
  boot2docker ssh '[ -f /var/lib/boot2docker/nsenter ] || docker run --rm -v /var/lib/boot2docker/:/target jpetazzo/nsenter'
  # Use bash if no command is specified
  args=${@:2}
  if [[ $# = 1 ]]; then
    args+=(/bin/bash)
  fi
  PID=$(boot2docker ssh "docker inspect --format '{{ .State.Pid }}' $1")
  boot2docker ssh -t sudo /var/lib/boot2docker/nsenter -m -u -n -i -p -t $PID "${args[@]}"
  unset args
}

boot2docker-up() {
  eval "$(boot2docker up | grep 'export DOCKER_HOST=tcp://')"
}

dockerip() { docker inspect $1 | grep IPAddress | cut -d '"' -f 4; }

alias dockerips='docker ps | tail -n +2 | while read cid b; do echo -n "$cid: "; docker inspect $cid | grep IPAddress | cut -d \" -f 4; done'

## setup boot2docker environment variables
## downloaded https://github.com/boot2docker/boot2docker/releases/download/v1.3.0/boot2docker.iso
## to /Users/kailianghe/.boot2docker/boot2docker.iso
export DOCKER_HOST=tcp://$(docker-ip):2376
export DOCKER_CERT_PATH=/Users/kailianghe/.boot2docker/certs/boot2docker-vm
export DOCKER_TLS_VERIFY=1