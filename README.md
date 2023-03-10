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

For configuring `geth` we're using configuration file, meaning that `geth` will
be started by simply by executing `geth --config get-config.toml`, without any
additional CLI arguments. It means that we need to create the config file, and
a `ConfigMap` from it.

Creation of the configuration file is well explained in this
[StackExchange answer](https://ethereum.stackexchange.com/questions/29063/geth-config-file-documentation#answer-29246).
In short, you should execute `geth` command with all CLI arguments set as
needed, with `dumpconfig` option. When `dumpconfig` option is set, instead of
launching `geth` will dump the config file that reflects all the CLI options set
and exits.

> **Note:** The only problem with this command is that it will try to create the
  directories you've set in `--datadir` and `--datadir.ancient`, and it will
  fail if you don't have permissions for these locations (i.e. if you set
  `/root/data`). The workaround is simple: just replace these protected paths
  with some dummy paths (i.e. replace `/root/data` with `/tmp/data`), execute
  the command, and then replace the dummy directory path with the real one in
  the resulting config file.

> **Note:** You should avoid changing paths (i.e. `--datadir`,
  `--datadir.ancient`, `--ethash.dagdir`) in the examples below because they are
  set in accordance with the mounted PVC. If you need to change these paths, you
  should also change [`geth.yaml`](./01-geth/geth.yaml) file appropriately. One
  possible reason for changing these paths can be to store _ancient data_ on a
  slower device (HDD), because it doesn't require performant I/O.

Here is an example of creating the config file for `sepolia` network:

```bash
geth dumpconfig \
    --sepolia \
    --datadir=/root/data/.ethereum \
    --datadir.ancient=/root/data/ancient-data \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.corsdomain=* \
    --http.vhosts=* \
    --http.api=admin,eth,debug,miner,net,txpool,personal,web3 \
    --ipcdisable \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts=* \
    --authrpc.jwtsecret=/root/jwttoken/jwtsecret.hex \
    --ethash.dagdir=/root/data/.ethash \
    > ./01-geth/geth-config.toml
```

The config generated by the previous command is in the
[`geth-config-sepolia.toml`](./01-geth/geth-config-sepolia.toml) file.

Here's an example for the main network:

```bash
geth dumpconfig \
    --syncmode=snap \
    --datadir=/root/data/.ethereum \
    --datadir.ancient=/root/data/ancient-data \
    --http \
    --http.addr=0.0.0.0 \
    --http.port=8545 \
    --http.corsdomain=* \
    --http.vhosts=* \
    --http.api=admin,eth,debug,miner,net,txpool,personal,web3 \
    --ipcdisable \
    --authrpc.addr=0.0.0.0 \
    --authrpc.port=8551 \
    --authrpc.vhosts=* \
    --authrpc.jwtsecret=/root/jwttoken/jwtsecret.hex \
    --ethash.dagdir=/root/data/.ethash \
    > ./01-geth/geth-config.toml
```

The config produced by the previous command is in the
[`geth-config-mainnet.toml`](./01-geth/geth-config-mainnet.toml) file.

> TODO(peske): Here I've set many different modules (`--http.api` values),
  simply by copying from somewhere. I should understand these modules well.

You can change the config file as needed, by changing CLI flags as in the
examples above. Once ready, you should generate the final config file at
`./01-geth/geth-config.toml`. After that you can create a `ConfigMap` from the
file by executing:

```bash
kubectl --namespace lighthouse create configmap geth-config --from-file=./01-geth/geth-config.toml
```

Then we can create a `StatefulSet` by executing:

```bash
kubectl apply -f ./01-geth/geth.yaml
```

# Install Lighthouse beacon

In the current version we still don't have a convenient way to configure the
beacon node. All the configuration is passed via CLI arguments, and is provided
directly in the `StatefulSet` manifest file. For this reason, currently there
are two `StatefulSet` manifest files:
[`beacon-statefulset-mainnet.yaml`](./02-beacon/beacon-statefulset-mainnet.yaml)
and
[`beacon-statefulset-sepolia.yaml`](./02-beacon/beacon-statefulset-sepolia.yaml).
The difference is in the CLI arguments provided.

> TODO(peske): Implement a better configuration mechanism.

When the desired CLI arguments are set, you can create the `StatefulSet` by
executing something like:

```bash
kubectl apply -f ./02-beacon/beacon-statefulset-mainnet.yaml
```

After that create the services by executing:

```bash
kubectl apply -f ./02-beacon/beacon-services.yaml
```

# Install `chaind`

Resources:

- https://github.com/wealdtech/chaind

The first step is to prepare the config file
[`chaind-config.yaml`](./03-chaind/chaind-config.yaml). There isn't much to do, 
but at very list you should probably change PostgreSQL password.

> **Note:** Don't push the password to git!

> **TODO(peske):** Investigate all config options.

Once the file is ready, you should create a `Secret` from it by executing:

```bash
kubectl --namespace lighthouse create secret generic chaind-config --from-file=./03-chaind/chaind-config.yaml
```

After that you can create `chaind` deployment by executing:

```bash
kubectl apply -f ./03-chaind/chaind.yaml
```
