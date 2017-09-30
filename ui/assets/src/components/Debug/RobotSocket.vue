<template lang="pug">
div
  .row
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagIn")
          q-item-main
            q-item-tile(label) IN
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagOut")
          q-item-main
            q-item-tile(label) OUT
    .col
      q-list(separator)
        q-item(tag="label")
          q-item-side
            q-toggle(v-model="flagSmall")
          q-item-main
            q-item-tile(label) SMALL
  template(v-if="events")
    .virtual-scroller-container
      virtual-scroller(:items="eventList", :item-height="21", :renderers="renderers", type-field="type", key-field="id", content-tag="table")
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
  debounce,
  pick
} from 'lodash'
import { VirtualScroller } from 'vue-virtual-scroller'

import SocketEventItem from './SocketEventItem.vue'
import RobotSocketEvents from './RobotSocketEvents.graphql'
import ObserveRobotSocketEvents from './ObserveRobotSocketEvents.graphql'

const KEEP_EVENT_MAX = 500

const persist = {
  get: () => null,
  remove: () => null,
  set: () => null
}

const prefKeys = [
  'flagIn',
  'flagOut',
  'flagSmall'
]

if (window.localStorage && typeof window.localStorage.setItem === 'function') {
  const key = 'RobotSocket.Preferences'
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
  event: SocketEventItem
}

export default {
  name: 'RobotSocket',
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
        query: RobotSocketEvents,
        fetchPolicy: 'network-only',
        variables () {
          return {
            exclude: this.exclusions
          }
        },
        result ({ data }) {
          this.updateEventList(data.events)
        },
        subscribeToMore: {
          document: ObserveRobotSocketEvents,
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
            if (nextEvents.length >= KEEP_EVENT_MAX) {
              return {
                events: nextEvents.slice(0, KEEP_EVENT_MAX - 1)
              }
            } else if ((prevEvents.length + nextEvents.length) > KEEP_EVENT_MAX) {
              const newEvents = prevEvents.slice(KEEP_EVENT_MAX - nextEvents.length)
              Array.prototype.push.apply(newEvents, nextEvents)
              return {
                events: newEvents
              }
            } else {
              return {
                events: [
                  ...prevEvents,
                  ...nextEvents
                ]
              }
            }
          }
        }
      }
    }
  },
  data () {
    const defaults = {
      flagIn: true,
      flagOut: false,
      flagSmall: false
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
      if (!this.flagIn) {
        exclusions.push('IN')
      }
      if (!this.flagOut) {
        exclusions.push('OUT')
      }
      if (!this.flagSmall) {
        exclusions.push('SMALL')
      }
      persist.set(pick(this, prefKeys))
      return exclusions
    }
  },
  methods: {
    updateEventList: debounce(function () {
      const events = this.events
      const reverseIndex = events.length - 1
      const eventList = events.map((event, index) => {
        const rindex = reverseIndex - index
        return {
          id: event.id,
          index: rindex,
          type: 'event',
          value: event
        }
      })
      eventList.reverse()
      this.eventList = eventList
    }, 500, { maxWait: 1000 })
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
