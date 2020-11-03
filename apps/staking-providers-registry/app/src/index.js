import React from 'react'
import ReactDOM from 'react-dom'
import { AragonApi } from '@aragon/api-react'
import App from './App'

const reducer = (state) => {
  if (state === null) {
    return {
      isSyncing: true,
      nodeOperatorsCount: '',
      getActiveNodeOperatorsCount: '',
      nodeOperators: [],
    }
  }
  return state
}

ReactDOM.render(
  <AragonApi reducer={reducer}>
    <App />
  </AragonApi>,
  document.getElementById('root')
)
