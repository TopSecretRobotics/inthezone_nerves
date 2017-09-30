import {
  ApolloClient,
  IntrospectionFragmentMatcher
} from 'apollo-client'
import {
  createNetworkInterface
} from 'apollo-phoenix-websocket'
import {
  socket,
  uri
} from 'src/configs/phoenix'

import VueApollo from 'vue-apollo'

const fragmentMatcher = new IntrospectionFragmentMatcher({
  introspectionQueryResultData: {
    __schema: {
      types: [
        {
          kind: 'INTERFACE',
          name: 'Event',
          possibleTypes: [
            { name: 'EventStatus' },
            { name: 'EventPing' },
            { name: 'EventPong' },
            { name: 'EventInfo' },
            { name: 'EventData' },
            { name: 'EventRead' },
            { name: 'EventWrite' },
            { name: 'EventSubscribe' },
            { name: 'EventUnsubscribe' }
          ]
        }
      ]
    }
  }
})

export const client = new ApolloClient({
  addTypename: true,
  connectToDevTools: true,
  fragmentMatcher: fragmentMatcher,
  networkInterface: createNetworkInterface({
    uri: uri,
    Socket: function () {
      return socket
    }
  })
})

export default new VueApollo({
  defaultClient: client
})
