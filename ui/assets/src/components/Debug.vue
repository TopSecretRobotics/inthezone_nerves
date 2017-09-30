<template lang="pug">
div
  q-toolbar(color="secondary")
    q-btn(flat)
      q-icon(name="bug_report")
    q-toolbar-title Debug
  q-tabs(color="tertiary")
    q-route-tab(name="home", slot="title", label="Home", :to="{ name: 'debug' }", exact)
    q-route-tab(name="localServer", slot="title", label="Local Server", :to="{ name: 'debugLocalServer' }")
    q-route-tab(name="localSocket", slot="title", label="Local Socket", :to="{ name: 'debugLocalSocket' }")
    q-route-tab(name="robotServer", slot="title", label="Robot Server", :to="{ name: 'debugRobotServer' }")
    q-route-tab(name="robotSocket", slot="title", label="Robot Socket", :to="{ name: 'debugRobotSocket' }")
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

export default {
  name: 'Debug',
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
  }
}
</script>
