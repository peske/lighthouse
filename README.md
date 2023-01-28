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
started simply with `geth --config get-config.toml`, without any additional CLI
arguments, and that you'll have to change the config appropriately to customize
it for your needs. Creation of the configuration file is well explained in this
[StackExchange answer](https://ethereum.stackexchange.com/questions/29063/geth-config-file-documentation#answer-29246).

Once the config file is created / edited appropriately, create a `ConfigMap`
from it by executing:

```bash
kubectl --namespace lighthouse
```

Create a `ConfigMap` with the entry point script by executing:

```bash
kubectl --namespace lighthouse create configmap start-geth-sh --from-file=./scripts/start-geth.sh
```

Create a `StatefulSet` by executing:

```bash
kubectl apply -f ./geth.yaml
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
