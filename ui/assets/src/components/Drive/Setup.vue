<template lang="pug">
.layout-padding
  pre {{ config }}
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
  QSlider,
  QToggle,
  QToolbar,
  QToolbarTitle
} from 'quasar'

export default {
  name: 'Setup',
  components: {
    QBtn,
    QChip,
    QIcon,
    QInput,
    QItem,
    QItemMain,
    QItemSide,
    QList,
    QSlider,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  props: {
    config: Object
  },
  data () {
    return {}
  }
}
</script>
