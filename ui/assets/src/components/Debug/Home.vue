<template lang="pug">
.layout-padding
  q-card(color="negative")
    q-card-title <q-icon name="warning"></q-icon> Warning!
    q-card-separator
    q-card-main
      p This can lock up the browser.
      p I don't recommend using it at all right now.
</template>

<script>
import {
  QBtn,
  QCard,
  QCardMain,
  QCardSeparator,
  QCardTitle,
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
  name: 'Home',
  components: {
    QBtn,
    QCard,
    QCardMain,
    QCardSeparator,
    QCardTitle,
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
  data () {
    return {}
  }
}
</script>
