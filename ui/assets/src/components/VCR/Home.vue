<template lang="pug">
.layout-padding
  q-card.bg-white
    q-card-main You are probably looking for the <router-link :to="{ name: 'vcrCassettes' }">cassettes</router-link> tab.
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
