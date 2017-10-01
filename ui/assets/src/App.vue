<template lang="pug">
#q-app
  q-layout(ref="layout", view="hHr LpR lFr", :left-class="{'bg-grey-2': true}", style="background-color: 'whitesmoke';")
    q-toolbar(slot="header", :color="toolbarColor")
      q-btn(flat, @click="$refs.layout.toggleLeft()")
        q-icon(name="menu")
      q-toolbar-title(padding="1") Top Secret Robotics
        span(slot="subtitle") {{ (isConnected) ? 'Connected' : 'Disconnected' }}
      .right-items
        template(v-if="isConnected")
          //- q-toolbar-title(padding="1")
            span(slot="subtitle") {{ robotTicks.toLocaleString() }}
          div(style="display: inline-block; margin-right: 10px;", v-if="cortex") {{ cortex.mainBattery.toFixed(2) }} {{ cortex.backupBattery.toFixed(2) }} {{ cortex.ticks.toLocaleString() }}
          q-spinner-puff(color="white", size="36")
            //- br
            //- span {{ robotTicks.toLocaleString() }}
        template(v-else)
          q-spinner-mat(color="white", size="36")
    div(slot="left")
      q-list(no-border, link, inset-delimiter)
        q-side-link(item, :to="{ name: 'dashboard' }", exact)
          q-item-side(icon="home")
          q-item-main(label="Dashboard")
        q-side-link(item, :to="{ name: 'motors' }")
          q-item-side(icon="adjust")
          q-item-main(label="Motors")
        q-side-link(item, :to="{ name: 'drive' }")
          q-item-side(icon="gamepad")
          q-item-main(label="Drive")
        q-side-link(item, :to="{ name: 'vcr' }")
          q-item-side(icon="sd_storage")
          q-item-main(label="VCR")
        q-side-link(item, :to="{ name: 'debug' }")
          q-item-side(icon="bug_report")
          q-item-main(label="Debug")
    router-view
</template>

<script>
import {
  QBtn,
  QIcon,
  QItem,
  QItemMain,
  QItemSide,
  QLayout,
  QList,
  QListHeader,
  QSideLink,
  QSpinnerMat,
  QSpinnerPuff,
  QToolbar,
  QToolbarTitle,
  QTooltip
} from 'quasar'

import gql from 'graphql-tag'
import socket from 'src/configs/phoenix'

/*
 * Root component
 */
export default {
  name: 'App',
  components: {
    QBtn,
    QIcon,
    QItem,
    QItemMain,
    QItemSide,
    QLayout,
    QList,
    QListHeader,
    QSideLink,
    QSpinnerMat,
    QSpinnerPuff,
    QToolbar,
    QToolbarTitle,
    QTooltip
  },
  apollo: {
    cortex: {
      query: gql`query Cortex {
        cortex {
          backupBattery
          connected
          mainBattery
          ticks
        }
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveCortex {
          observeCortex {
            backupBattery
            connected
            mainBattery
            ticks
          }
        }`,
        updateQuery: (previousResult, { subscriptionData }) => {
          return {
            cortex: subscriptionData.data.observeCortex
          }
        }
      }
    }
  },
  computed: {
    isConnected () {
      if (this.preventColorFlash === true) {
        return true
      }
      return !!(this.socketIsConnected && this.cortex && this.cortex.connected)
    },
    toolbarColor () {
      return (this.isConnected) ? 'primary' : 'negative'
    }
  },
  data () {
    return {
      preventColorFlash: true,
      preventColorFlashTimer: null,
      socketIsConnected: socket.isConnected()
    }
  },
  mounted () {
    socket.onOpen(this.socketOpen)
    socket.onClose(this.socketClose)
    this.preventColorFlashTimer = window.setTimeout(() => {
      this.preventColorFlash = false
    }, 1000)
  },
  beforeDestroy () {
    window.clearTimeout(this.preventColorFlashTimer)
    this.preventColorFlashTimer = null
  },
  methods: {
    socketClose () {
      this.socketIsConnected = false
    },
    socketOpen () {
      this.socketIsConnected = true
    }
  }
}
</script>

<style scoped>
.right-items {
  font-family: monospace;
}
</style>
