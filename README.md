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
kubectl apply -f ./namespace.yaml
```

## JWT token

To enable communication between the execution client (`geth`) and the consensus
client (`lighthouse`) using the new Engine API you need to generate a JWT Token
to be used for communication. You can create it by executing:

```bash
./generate-jwt.sh
```

This will create a `./jwttoken` directory, and `./jwttoken/jwtsecret.hex` file
in it. The next step is to create a `Secret` named `jwt-token` from the token by
executing:

```bash
kubectl --namespace lighthouse create secret generic jwt-token --from-file=./jwttoken/jwtsecret.hex
```

## Environment variables

The first step is to configure environment variables in [`.env`](./.env) file.
When it is done, crate a `ConfigMap` from it by executing:

```bash
kubectl --namespace lighthouse create configmap env-vars --from-env-file=./.env
```

# Install `geth`

Create a `ConfigMap` with the entry point script by executing:

```bash
kubectl --namespace lighthouse create configmap start-geth-sh --from-file=./scripts/start-geth.sh
```

Create a `StatefulSet` by executing:

```bash
kubectl apply -f ./geth.yaml
```
