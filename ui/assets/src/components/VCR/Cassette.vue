<template lang="pug">
.layout-padding
  template(v-if="cassette")
    q-card.bg-white
      //- q-card-title Details
      //- q-card-separator(inset)
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
      q-card-separator
      q-card-actions
        template(v-if="cassette.blank")
          q-btn(flat, color="primary", icon="fiber_manual_record", @click="vcrRecord()") Record
        template(v-else-if="cassette.startAt && !cassette.stopAt")
          q-btn(flat, color="primary", icon="stop", @click="vcrStop()") Stop
        template(v-else)
          q-btn(flat, color="negative", icon="delete_forever", @click="maybeVcrErase()") Erase
  pre {{ cassette }}
  //- pre {{ cassettes }}
  //- q-list(separator, link)
    q-item(v-for="cassette of cassettes", :key="cassette.id")
      template(v-if="cassette.blank")
        q-item-side(color="negative", icon="fiber_manual_record")
      template(v-else-if="cassette.startAt && !cassette.stopAt")
        q-item-side(color="warning", icon="pause_circle_filled")
      template(v-else)
        q-item-side(color="positive", icon="play_circle_filled")
      q-item-main {{ cassette.name }}
  //- q-card(color="negative")
    q-card-title <q-icon name="warning"></q-icon> Warning!
    q-card-separator
    q-card-main
      p This can lock up the browser.
      p I don't recommend using it at all right now.
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
  debounce,
  isEmpty
} from 'lodash'

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
      }
      // subscribeToMore: {
      //   document: gql`subscription ObserveMotors {
      //     observeMotors {
      //       id
      //       index
      //       ticks
      //       value
      //     }
      //   }`
      // }
    }
  },
  data () {
    return {}
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
    vcrRecord: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation VCRRecordCassette($id: ID!) {
          vcrRecord(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    vcrStop: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation VCRStopCassette($id: ID!) {
          vcrStop(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    vcrErase: debounce(function () {
      return this.$apollo.mutate({
        mutation: gql`mutation VCREraseCassette($id: ID!) {
          vcrErase(id: $id)
        }`,
        variables: {
          id: this.cassetteId
        }
      })
    }, 250),
    maybeVcrErase () {
      Dialog.create({
        title: 'Confirm',
        message: 'Are you sure you want to erase this cassette?',
        buttons: [
          {
            label: 'Erase It',
            classes: 'text-negative',
            handler: () => {
              this.vcrErase()
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
