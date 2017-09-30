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
          div(style="display: inline-block; margin-right: 10px;", v-if="robotMainBattery !== null && robotBackupBattery !== null && robotTicks !== null") {{ robotMainBattery.toFixed(2) }} {{ robotBackupBattery.toFixed(2) }} {{ robotTicks.toLocaleString() }}
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
    robotMainBattery: {
      query: gql`query RobotMainBattery {
        robotMainBattery: mainBattery
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveRobotMainBattery {
          observeMainBattery
        }`,
        updateQuery: (previousResult, { subscriptionData }) => {
          if (previousResult.robotMainBattery === subscriptionData.data.observeMainBattery) {
            return previousResult
          }
          return {
            robotMainBattery: subscriptionData.data.observeMainBattery
          }
        }
      }
    },
    robotBackupBattery: {
      query: gql`query RobotBackupBattery {
        robotBackupBattery: BackupBattery
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveRobotBackupBattery {
          observeBackupBattery
        }`,
        updateQuery: (previousResult, { subscriptionData }) => {
          if (previousResult.robotBackupBattery === subscriptionData.data.observeBackupBattery) {
            return previousResult
          }
          return {
            robotBackupBattery: subscriptionData.data.observeBackupBattery
          }
        }
      }
    },
    robotTicks: {
      query: gql`query RobotTicks {
        robotTicks: ticks
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveRobotTicks {
          observeTicks
        }`,
        updateQuery: (previousResult, { subscriptionData }) => {
          if (previousResult.robotTicks === subscriptionData.data.observeTicks) {
            return previousResult
          }
          return {
            robotTicks: subscriptionData.data.observeTicks
          }
        }
      }
    },
    serverIsConnected: {
      query: gql`query ServerIsConnected {
        serverIsConnected: isConnected
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveServerIsConnected {
          observeIsConnected
        }`,
        updateQuery: (previousResult, { subscriptionData }) => {
          if (previousResult.serverIsConnected === subscriptionData.data.observeIsConnected) {
            return previousResult
          }
          return {
            serverIsConnected: subscriptionData.data.observeIsConnected
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
      return !!(this.socketIsConnected && this.serverIsConnected)
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
