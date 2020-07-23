# DePool DAO smart contracts

## Development

### Requirements 

* NodeJs 10+

### Installing Aragon & other deps

Installation is local and don't require root privileges.

```bash
./bin/install-deps.sh
```

### Configuration

Can be specified in a local file `.dev.env`.

For options see [dev.env.default](dev.env.default).

The configuration is read only during new dao deployment.

### Starting & stopping processes

Three process have to be online during development: devchain (ganache), ipfs daemon, front-end:

```bash
./bin/start-dev.sh
```

To stop use:

```bash
./bin/stop-dev.sh
```

### New dao creation

```bash
./bin/deploy-dev-contracts.sh
```

The GUI for the created DAO can be accessed at `http://localhost:3000/?#/<dao_address>/`.

Note: `DAO_ID` must be unique in a blockchain.

### Other

To reset the devchain state, stop the processes and use:

```bash
./node_modules/.bin/aragon devchain --reset

<Ctrl+C>
```