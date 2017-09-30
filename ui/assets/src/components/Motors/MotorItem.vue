<template lang="pug">
q-item
  q-item-side
    q-chip(:color="color", pointing="right") {{ index }}
  template(v-if="editable")
    q-item-main
      q-slider(v-model="overrideSlider", :min="-127", :max="127", :step="1", label, snap, square, @change="changeSlider")
    q-item-side(right)
      input(type="number", v-model="overrideText", :min="-127", :max="127", :step="1", @change="changeText")
  template(v-else)
    q-item-main
      q-slider(:value="value", color="tertiary", :min="-127", :max="127", :step="1", :disable="true", label, snap, square)
    q-item-side(right)
      input(type="number", v-model="value", :min="-127", :max="127", :step="1", disabled)
</template>

<script>
import {
  QChip,
  QInput,
  QItem,
  QItemMain,
  QItemSide,
  QList,
  QSlider,
  QToggle
} from 'quasar'

import {
  debounce,
  isNaN,
  isNumber
} from 'lodash'
import gql from 'graphql-tag'

export default {
  name: 'MotorItem',
  components: {
    QChip,
    QInput,
    QItem,
    QItemMain,
    QItemSide,
    QList,
    QSlider,
    QToggle
  },
  props: {
    color: {
      type: String,
      default: 'tertiary'
    },
    editable: Boolean,
    motorId: String,
    index: Number,
    value: Number
  },
  data () {
    return {
      overrideSlider: 0,
      overrideText: 0
    }
  },
  watch: {
    editable () {
      this.overrideSlider = this.overrideText = this.value
    },
    value (value) {
      if (!this.editable) {
        this.override = value
      }
    }
  },
  methods: {
    changeSlider: debounce(function (value) {
      if (!this.editable) {
        return
      }
      if (isNumber(value)) {
        if (value < -127) {
          value = -127
        } else if (value > 127) {
          value = 127
        } else if (isNaN(value)) {
          value = this.value
        }
      } else {
        value = this.value
      }
      this.overrideSlider = this.overrideText = value
      this.changeValue(value)
    }, 100),
    changeText: debounce(function (event) {
      if (!this.editable) {
        return
      }
      if (event && event.target && event.target.value) {
        let value = this.overrideSlider
        try {
          value = parseInt(event.target.value)
        } catch (e) {
          value = this.overrideSlider
        }
        if (isNumber(value)) {
          if (value < -127) {
            value = -127
          } else if (value > 127) {
            value = 127
          } else if (isNaN(value)) {
            value = this.value
          }
        } else {
          value = this.value
        }
        this.overrideSlider = this.overrideText = value
        this.changeValue(value)
      }
    }, 250),
    changeValue: debounce(function (value) {
      this.updateValue(value)
    }, 250),
    updateValue (value) {
      return this.$apollo.mutate({
        mutation: gql`mutation UpdateMotorValue($input: UpdateMotorInput!) {
          updateMotor(input: $input) {
            motor {
              id
            }
          }
        }`,
        variables: {
          input: {
            clientMutationId: '',
            id: this.motorId,
            value: value
          }
        }
      })
    }
  }
}
</script>
