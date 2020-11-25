# Testnet for local e2e tests

# Install

## For MacOS X

Tested on MacOS Catalina 10.15.7 @MacBook Pro 15-inch 2018 2.6 GHz 6-core Intel Core i7 16GB RAM 2400MHz DDR4

1. install [homebrew](https://brew.sh/) `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"`

2. Using homebrew, install gnu-sed `brew install gnu-sed`. This is is important since default MacOSX sed has different interface.

How to check the sed is correct (GNU's)? It's output should look like this.

```sh
$ sed
Usage: gsed [OPTION]... {script-only-if-no-other-script} [input-file]...
<omitted>
GNU sed home page: <https://www.gnu.org/software/sed/>.
General help using GNU software: <https://www.gnu.org/gethelp/>.
```

3. Install nvm [Node Version Manager](https://github.com/nvm-sh/nvm#installing-and-updating)

4. Using nvm install node v12.20.0 (lts).

```sh
nvm install --lts 12
nvm alias default node
```

Check the version is correct

```sh
$ node -v
v12.20.0
```

5. Install Yarn package manager using its [official guide](https://classic.yarnpkg.com/en/docs/install/#mac-stable):

```sh
curl -o- -L https://yarnpkg.com/install.sh | bash
```

6. Clone the repository and run `yarn` in its root. It will install all requirements from package.json.


### For Ubuntu

TBD

## Start

Go to `e2e` folder and run `startup.sh -h` in it. It will print available invocation options.

```
bash-3.2$ ./startup.sh -h
./startup.sh [options]
 
options:
  -h | --help           show this help
  -r | --reset          force reset all blockchains state (clear all data)
  -d | --deploy         force try to deploy contracts
  -r1 | --reset1        force reset ETH1 blockchain state
  -r2 | --reset2        force reset ETH2 blockchain state
  -n | --nodes          start 2nd and 3d eth2 nodes
  -s | --snapshot       use snapshot instead deploy
  --stage [id]          uset stage id for snapshots (2 by default)
  -1 | --eth1           start only eth1 part
  -w | --web            also start Aragon web UI
  -ms | --makesnapshots create stage snapshots
  -o | --oracles        start oracles
  -os | --seed          seed mock data

```

For example, `./startup.sh -r -d` clears all the data, builds and deploys all the artifacts from scratch.

During the start, the script writes the parameters of artifacts it creates to the JSON file `deployed.json` located in the repository root.

## Artifacts and infrastructure

Here is the snippet to access all available artifacts programmatically. You can run it in the interactive python shell or in the jupyter notebook.

### Prepare

To avoid pollution of the system environment, we recommend to use venv module that stores all the modules in the separate folder, safe to remove after use.

```python
python3 -m venv <folder>
source venv/bin/activate
python
```

And you'll fall into clean virtual environment. Run `python` there and have fun in pure python CLI console

```python
python -m pip install web3 coincurve bip44
python
```

Or install jupyter notebook and start GUI to execute python snippets

```python
python -m pip install jupyter
jupyter notebook
```

### Load helpers and  artifacts

Just paste the snippets in the console or jupyter cell.

```python
LIDO_DAO_REPO_PATH = "/Users/kirill/Prog/Lido/lido-dao"
EPOCHS_PER_FRAME = 3
NETWORK_ID = '5'
DEPLOYED_JSON_PATH = f"{LIDO_DAO_REPO_PATH}/deployed.json"
LIDO_ARTIFACT = f'{LIDO_DAO_REPO_PATH}/artifacts/Lido.json'
ORACLE_ARTIFACT = f'{LIDO_DAO_REPO_PATH}/artifacts/LidoOracle.json'
NODE_OPS_REGISTRY_ARTIFACT = f'{LIDO_DAO_REPO_PATH}/artifacts/NodeOperatorsRegistry.json'
VOTING_ARTIFACT = f'{LIDO_DAO_REPO_PATH}/artifacts/Voting.json'
ACCOUNTS_JSON_PATH = f'{LIDO_DAO_REPO_PATH}/accounts.json'
WEB3_URL = 'http://206.81.31.11/rpc'
BEACON_URL = 'http://206.81.31.11:5052/eth/v1'

from web3 import Web3
from web3.middleware import geth_poa_middleware
from coincurve import PrivateKey
from bip44 import Wallet
from bip44.utils import get_eth_addr
import requests
import codecs
import json


class EthAccount:
    def __init__(self, secret_key):
        self.secret_key = PrivateKey(secret_key)
        self.public_key = self.secret_key.public_key.format()
        self.address = get_eth_addr(self.public_key)
    def __repr__(self):
        return(f"<{self.address}>")


def derive_accounts(wallet, max_depth):
    for i in range(max_depth):
        secret_key = wallet.derive_secret_key(f"m/44'/60'/0'/0/{i}")
        account = EthAccount(secret_key)
        balance = w3.eth.getBalance(account.address)
        print(f'Index:{i} Address: {account.address} Balance: {balance} (balance/1e18)')
    return accounts


def hex_to_base64(hex_str):
    return codecs.encode(codecs.decode(hex_str, 'hex'), 'base64').decode()


class API:
    def __init__(self, base):
        self.base = base
        self.headers = {'accept': 'application/json'}
    def get(self, url):
        r = requests.get(self.base + url, headers = self.headers)
        return r.json()
    def post(self, url, data=None):
        r = requests.post(self.base + url, headers = self.headers, data=data)
        return r.json()

# Parse artifacts from files into dict objects
with open(DEPLOYED_JSON_PATH) as f:
    deployed = json.load(f)

with open(LIDO_ARTIFACT) as f:
    lido_artifact = json.load(f)

with open(ORACLE_ARTIFACT) as f:
    oracle_artifact = json.load(f)

with open(NODE_OPS_REGISTRY_ARTIFACT) as f:
    nops_artifact = json.load(f)

with open(VOTING_ARTIFACT) as f:
    voting_artifact = json.load(f)

with open(ACCOUNTS_JSON_PATH) as f:
    accounts = json.load(f)
```

### Instantiate objects

Then initialize the objects

```python
# connect to nodes
w3 = Web3(Web3.HTTPProvider(WEB3_URL, request_kwargs={'timeout': 60}))
w3.middleware_onion.inject(geth_poa_middleware, layer=0)
beacon = API(BEACON_URL)
# read constants from deployed.json
mnemonic = accounts['e2e']['mnemonic']
lido_address = deployed['networks'][NETWORK_ID]['appProxies']['lido.lido.eth']
voting_address = deployed['networks'][NETWORK_ID]['appProxies']['voting.aragonpm.eth']
```

### Access

#### Ethereum 1.0 nodes

Web3 calls

```python
w3.eth.chainId
w3.eth.blockNumber
w3.clientVersion
# last block timestamp
now = int(w3.eth.getBlock('latest')['timestamp'])
```

#### Ethereum 1.0 accounts

```python
accounts = derive_accounts(Wallet(mnemonic), 50)
accounts
```

#### Eth 1 contracts

```python
lido = w3.eth.contract(
    address=lido_address,
    abi=lido_artifact['abi'],
)
registry_address = lido.functions.getOperators().call()
oracle_address = lido.functions.getOracle().call()
registry = w3.eth.contract(address=nops_address, abi=nops_artifact['abi'])
oracle = w3.eth.contract(address=oracle_address, abi=oracle_artifact['abi'])
```

```python
( epochsPerFrame, slotsPerEpoch, secondsPerSlot, genesisTime ) = oracle.functions.beaconSpec().call()
```

```python
depositedValidators, beaconValidators,beaconBalance = lido.functions.getBeaconStat().call()
depositedValidators, beaconValidators, beaconBalance
```

Compose the oracle members accounts

```python
members_addresses = oracle.functions.getOracleMembers().call()
members = []
for acc in accounts:
    if acc.address in members_addresses:
        members.append(acc)
members
```

Acsess hex-encoded secret key of the last member
```python
members[-1].secret_key.to_hex()
```

Read node operators registry

```
registry.functions.getActiveNodeOperatorsCount().call()
```

Read values from oracle

```python
epoch, frame_start, frame_end = oracle.functions.getCurrentFrame().call()
epoch, frame_start, frame_end
```

```
epoch = oracle.functions.getCurrentEpochId().call()
epoch
```

```python
oracle.functions.getQuorum().call()
oracle.functions.getCurrentEpochId().call()

```

Compose oracle report TX

```python
tx=oracle.functions.reportBeacon(1430, 128023448649000000000, 4).buildTransaction({
    'gasPrice': w3.eth.gasPrice,
    'nonce': w3.eth.getTransactionCount(members[2].address, 'latest'),
    'from': members[2].address
})
tx
```

```python
# try to play tx without actual
w3.eth.call(tx)
```

Sign, send the tx and wait for confirmation
CAUTION! THIS MAY BREAK THE ENVIRONMENT.
CAUTION! THIS MAY COST REAL MONEY

```
tx_signed = w3.eth.account.signTransaction(tx, members[2].secret_key.to_hex())
tx_hash = w3.eth.sendRawTransaction(tx_signed.rawTransaction)
tx_rcpt = w3.eth.waitForTransactionReceipt(tx_hash)
tx_rcpt['transactionHash']
```

#### Beacon nodes

Get version and spec parameters
```
beacon.get('/node/version')
beacon_genesis_time = int(beacon.get('/beacon/genesis')['data']['genesis_time'])
beacon_spec = beacon.get('/config/spec')
SECONDS_PER_SLOT = int(beacon_spec['data']['SECONDS_PER_SLOT'])
SLOTS_PER_EPOCH = int(beacon_spec['data']['SLOTS_PER_EPOCH'])
```

assert beacon and contract settings are in sync
```
assert epochsPerFrame == EPOCHS_PER_FRAME
assert slotsPerEpoch == SLOTS_PER_EPOCH
assert secondsPerSlot == SECONDS_PER_SLOT
assert genesisTime == beacon_genesis_time
```

Retrieve validators list
```
vals = beacon.get('/beacon/states/head/validators')['data']
print('Total validators: %s' % len(vals))
```