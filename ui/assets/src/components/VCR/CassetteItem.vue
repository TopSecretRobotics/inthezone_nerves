<template lang="pug">
q-item(:to="{ name: 'vcrCassette', params: { cassetteId: cassette.id } }")
  template(v-if="cassette.blank")
    q-item-side(color="negative", icon="fiber_manual_record")
  template(v-else-if="cassette.startAt && !cassette.stopAt")
    q-item-side(color="warning", icon="pause_circle_filled")
  template(v-else)
    q-item-side(color="positive", icon="play_circle_filled")
  q-item-main
    q-item-tile(label) {{ cassette.name }}
    q-item-tile(v-if="duration", sublabel) {{ duration }}
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

import moment from 'moment'

const pad = function (string) {
  return ('' + string).padStart(2, '0')
}

const padMS = function (string) {
  return ('' + string).padEnd(3, '0')
}

export default {
  name: 'CassetteItem',
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
  props: {
    cassette: {
      type: Object,
      required: true
    }
  },
  data () {
    return {
      duration: null,
      durationTimer: null
    }
  },
  beforeDestroy () {
    if (this.durationTimer !== null) {
      window.clearInterval(this.durationTimer)
      this.durationTimer = null
    }
  },
  watch: {
    cassette (cassette) {
      this.updateDuration(cassette)
    }
  },
  mounted () {
    if (this.cassette) {
      this.updateDuration(this.cassette)
    }
  },
  methods: {
    updateDuration (cassette) {
      if (this.durationTimer !== null) {
        window.clearInterval(this.durationTimer)
        this.durationTimer = null
      }
      if (cassette && cassette.startAt && cassette.stopAt) {
        const startAt = moment.utc(cassette.startAt)
        const stopAt = moment.utc(cassette.stopAt)
        const duration = moment.duration(stopAt.diff(startAt, 'milliseconds'), 'milliseconds')
        this.duration = `${pad(duration.get('minutes'))}:${pad(duration.get('seconds'))}.${padMS(duration.get('milliseconds'))}`
      } else if (cassette && cassette.startAt) {
        const startAt = moment.utc(cassette.startAt)
        const durationUpdate = () => {
          const stopAt = moment.utc()
          const duration = moment.duration(stopAt.diff(startAt, 'milliseconds'), 'milliseconds')
          this.duration = `${pad(duration.get('minutes'))}:${pad(duration.get('seconds'))}.${padMS(duration.get('milliseconds'))}`
        }
        durationUpdate()
        this.durationTimer = window.setInterval(durationUpdate, 25)
      } else {
        this.duration = null
      }
    }
  }
}
</script>
