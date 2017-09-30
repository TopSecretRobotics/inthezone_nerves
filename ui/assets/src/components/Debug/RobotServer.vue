<template lang="pug">
div
  .row
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagPing")
          q-item-main
            q-item-tile(label) PING
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagPong")
          q-item-main
            q-item-tile(label) PONG
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagInfo")
          q-item-main
            q-item-tile(label) INFO
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagData")
          q-item-main
            q-item-tile(label) DATA
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagPub")
          q-item-main
            q-item-tile(label) PUB
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagRead")
          q-item-main
            q-item-tile(label) READ
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagWrite")
          q-item-main
            q-item-tile(label) WRITE
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagSubscribe")
          q-item-main
            q-item-tile(label) SUBSCRIBE
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagUnsubscribe")
          q-item-main
            q-item-tile(label) UNSUBSCRIBE
  template(v-if="events")
    .virtual-scroller-container
      virtual-scroller(:items="eventList", :item-height="21", :renderers="renderers", type-field="type", key-field="index", content-tag="table")
</template>

<script>
import {
  QBtn,
  QChip,
  QIcon,
  QInfiniteScroll,
  QInput,
  QItem,
  QItemMain,
  QItemSide,
  QItemTile,
  QList,
  QSlider,
  QSpinnerDots,
  QToggle,
  QToolbar,
  QToolbarTitle
} from 'quasar'

import {
  pick
} from 'lodash'
import { VirtualScroller } from 'vue-virtual-scroller'

import ServerEventItem from './ServerEventItem.vue'
import RobotServerEvents from './RobotServerEvents.graphql'
import ObserveRobotServerEvents from './ObserveRobotServerEvents.graphql'

const KEEP_EVENT_MAX = 5000

const persist = {
  get: () => null,
  remove: () => null,
  set: () => null
}

const prefKeys = [
  'flagPing',
  'flagPong',
  'flagInfo',
  'flagData',
  'flagPub',
  'flagRead',
  'flagWrite',
  'flagSubscribe',
  'flagUnsubscribe'
]

if (window.localStorage && typeof window.localStorage.setItem === 'function') {
  const key = 'RobotServer.Preferences'
  persist.get = function () {
    let value = window.localStorage.getItem(key)
    if (value) {
      try {
        value = JSON.parse(value)
      } catch (e) {
        window.localStorage.removeItem(key)
        value = null
      }
    }
    return value
  }
  persist.remove = function () {
    return window.localStorage.removeItem(key)
  }
  persist.set = function (value) {
    return window.localStorage.setItem(key, JSON.stringify(value))
  }
}

const renderers = {
  event: ServerEventItem
}

export default {
  name: 'RobotServer',
  components: {
    // VirtualList,
    VirtualScroller,
    QBtn,
    QChip,
    QIcon,
    QInfiniteScroll,
    QInput,
    QItem,
    QItemMain,
    QItemSide,
    QItemTile,
    QList,
    QSlider,
    QSpinnerDots,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  apollo: {
    events () {
      return {
        query: RobotServerEvents,
        fetchPolicy: 'network-only',
        variables () {
          return {
            exclude: this.exclusions
          }
        },
        result ({ data }) {
          const reverseIndex = data.events.length - 1
          const eventList = data.events.map((event, index) => {
            const rindex = reverseIndex - index
            return {
              index: rindex,
              type: 'event',
              value: event
            }
          })
          eventList.reverse()
          this.eventList = eventList
        },
        subscribeToMore: {
          document: ObserveRobotServerEvents,
          variables: () => {
            return {
              exclude: this.exclusions
            }
          },
          updateQuery: (previousResult, { subscriptionData }) => {
            const prevEvents = previousResult.events
            const nextEvents = subscriptionData.data.events
            if (nextEvents.length === 0) {
              return previousResult
            }
            const newEvents = [
              ...prevEvents,
              ...nextEvents
            ]
            while (newEvents.length > KEEP_EVENT_MAX) {
              newEvents.shift()
            }
            return {
              events: newEvents
            }
          }
        }
      }
    }
  },
  data () {
    const defaults = {
      flagPing: false,
      flagPong: false,
      flagInfo: true,
      flagData: true,
      flagPub: false,
      flagRead: true,
      flagWrite: true,
      flagSubscribe: true,
      flagUnsubscribe: true
    }
    let prefs = persist.get()
    try {
      prefs = pick(prefs, prefKeys)
    } catch (e) {
      persist.remove()
      prefs = {}
    }
    prefs = Object.assign({}, defaults, prefs)
    return {
      ...prefs,
      eventList: [],
      renderers
    }
  },
  computed: {
    exclusions () {
      const exclusions = []
      if (!this.flagPing) {
        exclusions.push('PING')
      }
      if (!this.flagPong) {
        exclusions.push('PONG')
      }
      if (!this.flagInfo) {
        exclusions.push('INFO')
      }
      if (!this.flagData) {
        exclusions.push('DATA')
      }
      if (!this.flagPub) {
        exclusions.push('PUB')
      }
      if (!this.flagRead) {
        exclusions.push('READ')
      }
      if (!this.flagWrite) {
        exclusions.push('WRITE')
      }
      if (!this.flagSubscribe) {
        exclusions.push('SUBSCRIBE')
      }
      if (!this.flagUnsubscribe) {
        exclusions.push('UNSUBSCRIBE')
      }
      persist.set(pick(this, prefKeys))
      return exclusions
    }
  }
}
</script>

<style scoped>
.virtual-scroller-container {
  overflow: hidden;
  position: relative;
  top: 0;
  bottom: 0;
  left: 0;
  right: 0;
}
</style>
