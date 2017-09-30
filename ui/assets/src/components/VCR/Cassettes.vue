<template lang="pug">
div
  //- pre {{ cassettes }}
  template(v-if="cassettes")
    q-list(separator, link)
      q-item(v-for="cassette of cassettes", :key="cassette.id", :to="{ name: 'vcrCassette', params: { cassetteId: cassette.id } }")
        template(v-if="cassette.blank")
          q-item-side(color="negative", icon="fiber_manual_record")
        template(v-else-if="cassette.startAt && !cassette.stopAt")
          q-item-side(color="warning", icon="pause_circle_filled")
        template(v-else)
          q-item-side(color="positive", icon="play_circle_filled")
        q-item-main
          q-item-tile(label) {{ cassette.name }}
  //- q-card(color="negative")
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
  QItemTile,
  QList,
  QSlider,
  QToggle,
  QToolbar,
  QToolbarTitle
} from 'quasar'

export default {
  name: 'Cassettes',
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
    QItemTile,
    QList,
    QSlider,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  props: ['cassettes'],
  data () {
    return {}
  }
}
</script>
