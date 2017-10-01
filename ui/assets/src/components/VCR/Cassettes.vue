<template lang="pug">
div
  template(v-if="cassettes")
    q-list(separator, link)
      template(v-for="cassette of cassettes")
        cassette-item(:key="cassette.id", :cassette="cassette")
      //- q-item(v-for="cassette of cassettes", :key="cassette.id", :to="{ name: 'vcrCassette', params: { cassetteId: cassette.id } }")
        template(v-if="cassette.blank")
          q-item-side(color="negative", icon="fiber_manual_record")
        template(v-else-if="cassette.startAt && !cassette.stopAt")
          q-item-side(color="warning", icon="pause_circle_filled")
        template(v-else)
          q-item-side(color="positive", icon="play_circle_filled")
        q-item-main
          q-item-tile(label) {{ cassette.name }}
          q-item-tile(v-if="durations[cassette.id]", sublabel) {{ durations[cassette.id] }}
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

import gql from 'graphql-tag'

import CassetteItem from './CassetteItem.vue'

export default {
  name: 'Cassettes',
  components: {
    CassetteItem,
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
  apollo: {
    cassettes: {
      query: gql`query Cassettes {
        cassettes {
          id
          name
          blank
          startAt
          stopAt
          insertedAt
          updatedAt
        }
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveCassettes {
          observeCassettes {
            id
            name
            blank
            startAt
            stopAt
            insertedAt
            updatedAt
          }
        }`
      }
    }
  },
  data () {
    return {}
  }
}
</script>
