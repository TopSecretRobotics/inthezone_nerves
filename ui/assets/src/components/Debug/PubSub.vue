<template lang="pug">
.layout-padding
  template(v-if="pubsub")
    q-card.bg-white
      q-card-main
        pre {{ pubsub }}
      q-card-separator
      q-card-actions
        q-btn(flat, @click="refresh()") Refresh
  template(v-else)
    q-card(color="negative")
      q-card-title <q-icon name="warning"></q-icon> Error!
      q-card-separator
      q-card-main
        p Unable to fetch Publish/Subscription information from robot.
      q-card-separator
      q-card-actions
        q-btn(flat, @click="refresh()") Refresh
</template>

<script>
import {
  QBtn,
  QCard,
  QCardActions,
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

import gql from 'graphql-tag'
import {
  debounce
} from 'lodash'

export default {
  name: 'PubSub',
  components: {
    QBtn,
    QCard,
    QCardActions,
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
  apollo: {
    pubsub: {
      query: gql`query PubSub {
        pubsub {
          count
          free
          max
          list {
            subId
            topic
            subtopic
          }
        }
      }`,
      fetchPolicy: 'network-only'
    }
  },
  data () {
    return {}
  },
  methods: {
    refresh: debounce(function () {
      this.$apollo.queries.pubsub.refetch()
    }, 250)
  }
}
</script>
