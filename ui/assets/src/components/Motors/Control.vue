<template lang="pug">
div
  template(v-if="motors")
    q-list(separator)
      q-item(tag="label")
        q-item-side
          q-toggle(color="primary", v-model="editable")
        q-item-main(inset)
          q-item-tile(label) Manual Override
      //- template(v-if="editable")
      q-item(link, @click="reverseAllMotors()").bg-warning
        q-item-side(icon="warning")
        q-item-main(inset)
          q-item-tile(label) Reverse All Motors
      motor-item(v-for="motor of motors", :key="motor.id", :color="colors[motor.index]", :index="motor.index", :motor-id="motor.id", :value="motor.value", :editable="editable")
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
  QItemTile,
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

import MotorItem from '@/Motors/MotorItem.vue'

const Motor10ColorNames = [
  'cyan',
  'blue',
  'indigo',
  'purple',
  'red',
  'orange',
  'amber',
  'lime',
  'green',
  'teal'
]

export default {
  name: 'Control',
  components: {
    MotorItem,
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
    QItemTile,
    QList,
    QSlider,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  apollo: {
    motors: {
      query: gql`query Motors {
        motors {
          id
          index
          ticks
          value
        }
      }`,
      fetchPolicy: 'network-only',
      subscribeToMore: {
        document: gql`subscription ObserveMotors {
          observeMotors {
            id
            index
            ticks
            value
          }
        }`
      }
    }
  },
  data () {
    return {
      colors: Motor10ColorNames,
      editable: false
    }
  },
  methods: {
    reverseAllMotors: debounce(function () {
      this.editable = false
      return this.$apollo.mutate({
        mutation: gql`mutation ReverseAllMotors {
          reverseAllMotors
        }`
      })
    }, 250),
    stopAllMotors: debounce(function () {
      this.editable = false
      return this.$apollo.mutate({
        mutation: gql`mutation StopAllMotors {
          stopAllMotors
        }`
      })
    }, 250)
  }
}
</script>
