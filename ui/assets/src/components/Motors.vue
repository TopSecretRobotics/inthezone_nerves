<template lang="pug">
div
  q-toolbar(color="secondary")
    q-btn(flat)
      q-icon(name="adjust")
    q-toolbar-title Motors
  q-tabs(color="tertiary")
    q-route-tab(name="overview", slot="title", label="Overview", :to="{ name: 'motors' }", exact)
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
  }
}
</script>
