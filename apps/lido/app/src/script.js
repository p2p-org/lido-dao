import 'core-js/stable'
import 'regenerator-runtime/runtime'
import Aragon, { events } from '@aragon/api'
import { fromWei } from 'web3-utils'

const app = new Aragon()

app.store(
  async (state, { event }) => {
    const nextState = {
      ...state,
    }

    try {
      switch (event) {
        case 'Stopped':
          return { ...nextState, isStopped: await isStopped() }
        case 'Resumed':
          return { ...nextState, isStopped: await isStopped() }
        case 'FeeSet':
          return { ...nextState, fee: await getFee() }
        case 'FeeDistributionSet':
          return { ...nextState, feeDistribution: await getFeeDistribution() }
        case 'WithdrawalCredentialsSet':
          return {
            ...nextState,
            withdrawalCredentials: await getWithdrawalCredentials(),
          }
        case 'Unbuffered':
          return { ...nextState, bufferedEther: await getBufferedEther() }
        case events.SYNC_STATUS_SYNCING:
          return { ...nextState, isSyncing: true }
        case events.SYNC_STATUS_SYNCED:
          return { ...nextState, isSyncing: false }
        default:
          return state
      }
    } catch (err) {
      console.log(err)
    }
  },
  {
    init: initializeState(),
  }
)

/***********************
 *                     *
 *   Event Handlers    *
 *                     *
 ***********************/

function initializeState() {
  return async (cachedState) => {
    return {
      ...cachedState,
      isStopped: await isStopped(),
      fee: await getFee(),
      feeDistribution: await getFeeDistribution(),
      withdrawalCredentials: await getWithdrawalCredentials(),
      bufferedEther: await getBufferedEther(),
      totalControlledEther: await getTotalControlledEther(),
      token: await getToken(),
      validatorRegistrationContract: await getValidatorRegistrationContract(),
      oracle: await getOracle(),
      // operators: await getOperators(),
      // treasury: await getTreasury(),
      // insuranceFund: await getInsuranceFund(),
      ether2Stat: await getEther2Stat(),
    }
  }
}

// API
function isStopped() {
  return app.call('isStopped').toPromise()
}

function getFee() {
  return app.call('getFee').toPromise()
}

function getFeeDistribution() {
  return app.call('getFeeDistribution').toPromise()
}

function getWithdrawalCredentials() {
  return app.call('getWithdrawalCredentials').toPromise()
}

async function getBufferedEther() {
  return fromWei(await app.call('getBufferedEther').toPromise())
}

async function getTotalControlledEther() {
  return fromWei(await app.call('getTotalControlledEther').toPromise())
}

function getToken() {
  return app.call('getToken').toPromise()
}

function getValidatorRegistrationContract() {
  return app.call('getValidatorRegistrationContract').toPromise()
}

function getOracle() {
  return app.call('getOracle').toPromise()
}

// async function getOperators() {
//   return await app.call('getOperators').toPromise()
// }

// async function getTreasury() {
//   return await app.call('getTreasury').toPromise()
// }

// async function getInsuranceFund() {
//   return await app.call('getInsuranceFund').toPromise()
// }

async function getEther2Stat() {
  const stat = await app.call('getEther2Stat').toPromise()
  return {
    Deposited: fromWei(stat.deposited),
    Remote: fromWei(stat.remote),
  }
}
