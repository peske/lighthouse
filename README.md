> **IMPORTANT: Work in progress!** The repository is not ready for use.

# What?

Kubernetes manifests for deploying
[Lighthouse](https://github.com/sigp/lighthouse) with
[`geth`](https://geth.ethereum.org/).

# Resources

- https://github.com/kimpers/lighthouse-docker
- https://geth.ethereum.org/docs/getting-started/consensus-clients

# Preparation

Create the `lighthouse` namespace:

```bash
kubectl apply -f ./00-prepare/namespace.yaml
```

To enable communication between the execution client (`geth`) and the consensus
client (`lighthouse`) using the new Engine API you need to generate a JWT Token
to be used for communication. You can create it by executing:

```bash
./00-prepare/generate-jwt.sh
```

This will create a `./jwttoken` directory, and `./jwttoken/jwtsecret.hex` file
in it. The next step is to create a `Secret` named `jwt-token` from the token by
executing:

```bash
kubectl --namespace lighthouse create secret generic jwt-token --from-file=./jwttoken/jwtsecret.hex
```

# Install `geth`

For configuring `geth` we're using configuration file
[`geth-config.toml`](./01-geth/geth-config.toml). It means that `geth` will be
started by executing:

```bash
geth --config get-config.toml
```

 `geth --config get-config.toml`, without any additional CLI
arguments, and that you'll have to change the config appropriately to customize
it for your needs. Creation of the configuration file is well explained in this
[StackExchange answer](https://ethereum.stackexchange.com/questions/29063/geth-config-file-documentation#answer-29246).

The current version of the config file is created by executing:

```bash
geth dumpconfig \
    --sepolia \
    --datadir=/root/data/.ethereum \
    --datadir.ancient=/root/data/ancient-data \
    --http \
    --http.addr=0.0.0.0 \
    --http.vhosts=* \
    --http.api=eth,net \
    --ipcdisable \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts=* \
    --authrpc.jwtsecret=/root/jwttoken/jwtsecret.hex \
    --ethash.dagdir=/root/data.ethash \
    > ./01-geth/geth-config.toml
```

> **Note:** The previous command will fail for a ridiculous reason: you don't
  have permissions to create `/root/data` directory, and for some reason even
  with `dumpconfig` the command tries to create this directory. The simplest
  workarround would be to replace `/root/` with a dummy path `/tmp/`, execute
  the command, and then find and replace `/tmp/` with `/root/` in the resulting
  config file.

> **Note:** You should not change the paths in the command above because the
  appropriate volumes and secrets will be mounted at these path later. If for
  any reason you have to change these paths, you should also change
  [`geth.yaml`](./01-geth/geth.yaml) file appropriately.

Once the config file is created / edited appropriately, create a `ConfigMap`
from it by executing:

```bash
kubectl --namespace lighthouse create configmap geth-config --from-file=./01-geth/geth-config.toml
```

After that we can create a `StatefulSet` by executing:

```bash
kubectl apply -f ./01-geth/geth.yaml
```

# Install Lighthouse beacon

Create a `ConfigMap` with the entry point script by executing:

```bash
kubectl --namespace lighthouse create configmap start-beacon-node-sh --from-file=./scripts/start-beacon-node.sh
```

Create a `StatefulSet` by executing:

```bash
kubectl apply -f ./beacon.yaml
```
