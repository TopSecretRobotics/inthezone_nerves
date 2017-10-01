<template lang="pug">
div
  q-toolbar(color="secondary")
    q-btn(flat)
      q-icon(name="gamepad")
    q-toolbar-title Drive
    q-btn(color="negative", icon="stop", @click="stopAllMotors()") Stop All Motors
  q-tabs(color="tertiary")
    q-route-tab(name="control", slot="title", label="Control", :to="{ name: 'drive' }", exact)
    q-route-tab(name="setup", slot="title", label="Setup", :to="{ name: 'driveSetup' }")
  router-view(:config="config")
</template>

<script>
import {
  QBtn,
  QChip,
  QIcon,
  QInput,
  QItem,
  QItemMain,
  QItemSide,
  QList,
  QRouteTab,
  QSlider,
  QTabs,
  QToggle,
  QToolbar,
  QToolbarTitle
} from 'quasar'

import gql from 'graphql-tag'
import {
  debounce
} from 'lodash'

export default {
  name: 'Drive',
  components: {
    QBtn,
    QChip,
    QIcon,
    QInput,
    QItem,
    QItemMain,
    QItemSide,
    QList,
    QRouteTab,
    QSlider,
    QTabs,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  apollo: {
    config: {
      query: gql`query Config {
        config {
          drive {
            id
            northeastMotor
            northwestMotor
            southeastMotor
            southwestMotor
            northeastReversed
            northwestReversed
            southeastReversed
            southwestReversed
          }
        }
      }`,
      fetchPolicy: 'network-only'
    }
  },
  methods: {
    stopAllMotors: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation StopAllMotors {
          stopAllMotors
        }`
      })
    }, 250)
  }
}
</script>
