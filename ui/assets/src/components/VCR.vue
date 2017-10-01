<template lang="pug">
div
  q-toolbar(color="secondary")
    q-btn(flat)
      q-icon(name="sd_storage")
    q-toolbar-title VCR
    q-btn(color="negative", icon="stop", @click="stopAllMotors()") Stop All Motors
  q-tabs(color="tertiary")
    q-route-tab(name="home", slot="title", label="Home", :to="{ name: 'vcr' }", exact)
    q-route-tab(name="cassettes", slot="title", label="Cassettes", :to="{ name: 'vcrCassettes' }")
  router-view
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
  name: 'VCR',
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
