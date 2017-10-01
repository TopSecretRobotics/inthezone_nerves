<template lang="pug">
div
  q-toolbar(color="secondary")
    q-btn(flat)
      q-icon(name="adjust")
    q-toolbar-title Motors
    q-btn(color="negative", icon="stop", @click="stopAllMotors()") Stop All Motors
  q-tabs(color="tertiary")
    q-route-tab(name="control", slot="title", label="Control", :to="{ name: 'motors' }", exact)
    q-route-tab(name="graph", slot="title", label="Graph", :to="{ name: 'motorsGraph' }")
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
  name: 'Motors',
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
