<template lang="pug">
.layout-padding
  template(v-if="cassette")
    q-card.bg-white
      q-item(link, @click="editName")
        template(v-if="cassette.blank")
          q-item-side(color="negative", icon="fiber_manual_record")
        template(v-else-if="cassette.startAt && !cassette.stopAt")
          q-item-side(color="warning", icon="pause_circle_filled")
        template(v-else)
          q-item-side(color="positive", icon="play_circle_filled")
        q-item-main(inset)
          q-item-tile(label) {{ cassette.name }}
          q-item-tile(sublabel) Name
      template(v-if="duration")
        q-item-separator
        q-item
          q-item-side(icon="timer")
          q-item-main(inset)
            q-item-tile(label) {{ duration }}
            q-item-tile(sublabel) Duration
      template(v-if="runtime")
        q-item-separator
        q-item
          q-item-side(icon="av_timer")
          q-item-main(inset)
            q-item-tile(label) {{ runtime }}
            q-item-tile(sublabel) Runtime
      q-card-separator
      q-card-actions(v-if="!cassette.playAt")
        template(v-if="cassette.blank")
          q-btn(flat, color="primary", icon="fiber_manual_record", @click="cassetteRecord()") Record
        template(v-else-if="cassette.startAt && !cassette.stopAt")
          q-btn(flat, color="positive")
            q-spinner-gears(color="positive", :size="36")
            span &nbsp;Recording
          q-btn(flat, color="primary", icon="stop", @click="cassetteStop()") Stop
        template(v-else)
          q-btn(flat, color="positive", icon="play_arrow", @click="cassettePlay()") Play
          q-btn(flat, color="negative", icon="delete_forever", @click="maybeCassetteErase()") Erase
      q-card-actions(v-else)
        q-btn(flat, color="positive")
          q-spinner-gears(color="positive", :size="36")
          span &nbsp;Playing
        q-btn(flat, color="primary", icon="stop", @click="cassetteStop()") Stop
    template(v-if="events")
      .row
        .col
          q-list(separator)
            q-collapsible(icon="grid_on", label="Table")
              q-card.bg-white
                .table-scrollable
                  table.q-table.compact.striped-odd.vertical-separator(style="width: 100%;")
                    thead
                      tr
                        th Ticks
                        th 0
                        th 1
                        th 2
                        th 3
                        th 4
                        th 5
                        th 6
                        th 7
                        th 8
                        th 9
                    tbody
                      tr(v-for="(event, index) of events", :key="index")
                        td {{ event.ticks.toLocaleString() }}
                        td {{ event['0'] }}
                        td {{ event['1'] }}
                        td {{ event['2'] }}
                        td {{ event['3'] }}
                        td {{ event['4'] }}
                        td {{ event['5'] }}
                        td {{ event['6'] }}
                        td {{ event['7'] }}
                        td {{ event['8'] }}
                        td {{ event['9'] }}
            q-collapsible(v-if="convex", icon="code", label="Convex")
              pre {{ convex.toString() }}
            q-collapsible(v-if="pros", icon="code", label="PROS")
              pre {{ pros.toString() }}
</template>

<script>
import {
  Dialog,
  QBtn,
  QCard,
  QCardActions,
  QCardMain,
  QCardSeparator,
  QCardTitle,
  QChip,
  QCollapsible,
  QIcon,
  QInput,
  QItem,
  QItemMain,
  QItemSeparator,
  QItemSide,
  QItemTile,
  QList,
  QSlider,
  QSpinnerGears,
  QToggle,
  QToolbar,
  QToolbarTitle
} from 'quasar'

import gql from 'graphql-tag'
import {
  debounce,
  isEmpty
} from 'lodash'

import moment from 'moment'

const pad = function (string) {
  return ('' + string).padStart(2, '0')
}

const padMS = function (string) {
  return ('' + string).padEnd(3, '0')
}

import ConvexCode from './ConvexCode.js'
import PROSCode from './PROSCode.js'

export default {
  name: 'Cassette',
  components: {
    QBtn,
    QCard,
    QCardActions,
    QCardMain,
    QCardSeparator,
    QCardTitle,
    QChip,
    QCollapsible,
    QIcon,
    QInput,
    QItem,
    QItemMain,
    QItemSeparator,
    QItemSide,
    QItemTile,
    QList,
    QSlider,
    QSpinnerGears,
    QToggle,
    QToolbar,
    QToolbarTitle
  },
  props: ['cassetteId'],
  apollo: {
    cassette: {
      query: gql`query GetCassette($id: ID!) {
        cassette: node(id: $id) {
          id
          ... on Cassette {
            name
            blank
            data {
              ticks
              motors {
                index
                value
              }
            }
            runtime
            playAt
            startAt
            stopAt
            insertedAt
            updatedAt
          }
        }
      }`,
      fetchPolicy: 'network-only',
      variables () {
        return {
          id: this.cassetteId
        }
      },
      skip () {
        return !this.cassetteId
      },
      subscribeToMore: {
        document: gql`subscription ObserveCassette($id: ID!) {
          cassette: observeCassette(id: $id) {
            id
            name
            blank
            data {
              ticks
              motors {
                index
                value
              }
            }
            runtime
            playAt
            startAt
            stopAt
            insertedAt
            updatedAt
          }
        }`,
        variables () {
          return {
            id: this.cassetteId
          }
        },
        skip () {
          return !this.cassetteId
        }
      }
    }
  },
  data () {
    return {
      duration: null,
      durationTimer: null,
      runtime: null,
      events: null,
      convex: null,
      pros: null
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
      if (cassette && cassette.runtime !== null) {
        const runtime = moment.duration(cassette.runtime, 'milliseconds')
        this.runtime = `${pad(runtime.get('minutes'))}:${pad(runtime.get('seconds'))}.${padMS(runtime.get('milliseconds'))}`
      } else {
        this.runtime = null
      }
      if (cassette && cassette.data) {
        const events = []
        let firstTicks = null
        let secondTicks = null
        cassette.data.forEach(({ ticks, motors }) => {
          if (firstTicks === null) {
            firstTicks = ticks
          } else if (secondTicks === null) {
            secondTicks = ticks
          }
          const event = {
            ticks: (ticks - ((secondTicks === null) ? firstTicks : secondTicks)),
            '0': null,
            '1': null,
            '2': null,
            '3': null,
            '4': null,
            '5': null,
            '6': null,
            '7': null,
            '8': null,
            '9': null
          }
          motors.forEach(({ index, value }) => {
            event[`${index}`] = value
          })
          events.push(event)
        })
        this.events = events
      } else {
        this.events = null
      }
      if (cassette && !cassette.blank && cassette.startAt && cassette.stopAt) {
        this.convex = new ConvexCode(this.events)
        this.pros = new PROSCode(this.events)
      } else {
        this.convex = null
        this.pros = null
      }
    }
  },
  methods: {
    editName () {
      Dialog.create({
        title: 'Rename',
        form: {
          name: {
            type: 'text',
            label: 'Name',
            model: this.cassette.name
          }
        },
        buttons: [
          'Cancel',
          {
            label: 'Save',
            classes: 'bg-primary text-white',
            handler: (data) => {
              if (!isEmpty(data.name) && !isEmpty(data.name.trim()) && this.cassette.name !== data.name) {
                this.update({ name: data.name.trim() })
              }
            }
          }
        ]
      })
    },
    update (data) {
      return this.$apollo.mutate({
        mutation: gql`mutation UpdateCassette($input: UpdateCassetteInput!) {
          updateCassette(input: $input) {
            clientMutationId
            cassette {
              id
            }
          }
        }`,
        variables: {
          input: {
            ...data,
            clientMutationId: '',
            id: this.cassetteId
          }
        }
      })
    },
    cassettePlay: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation CassettePlay($id: ID!) {
          cassettePlay(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    cassetteRecord: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation CassetteRecord($id: ID!) {
          cassetteRecord(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    cassetteStop: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation CassetteStop($id: ID!) {
          cassetteStop(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    cassetteErase: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation CassetteErase($id: ID!) {
          cassetteErase(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    maybeCassetteErase () {
      Dialog.create({
        title: 'Confirm',
        message: 'Are you sure you want to erase this cassette?',
        buttons: [
          {
            label: 'Erase It',
            classes: 'text-negative',
            handler: () => {
              this.cassetteErase()
            }
          },
          {
            label: 'Back to safety'
          }
        ]
      })
    }
  }
}
</script>

<style scoped>
.table-scrollable {
  width: 100%;
  overflow-x: auto;
}
</style>
