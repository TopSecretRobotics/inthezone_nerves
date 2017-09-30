<template lang="pug">
.zone-container
  .zone(ref="control")
    .debug
      ul
        li &nbsp;x: {{ x }}
        li &nbsp;y: {{ y }}
        li ne: {{ ne }}
        li nw: {{ nw }}
        li se: {{ se }}
        li sw: {{ sw }}
</template>

<script>
/* eslint-disable */
import {
  QBtn,
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
import nipplejs from 'nipplejs'
import Vue from 'vue'

/* eslint-disable */
const driveSpeedTable = [
   0,  0,  0,  0,  0,  0,  0,  0,  0,  0,
   0, 21, 21, 21, 22, 22, 22, 23, 24, 24,
  25, 25, 25, 25, 26, 27, 27, 28, 28, 28,
  28, 29, 30, 30, 30, 31, 31, 32, 32, 32,
  33, 33, 34, 34, 35, 35, 35, 36, 36, 37,
  37, 37, 37, 38, 38, 39, 39, 39, 40, 40,
  41, 41, 42, 42, 43, 44, 44, 45, 45, 46,
  46, 47, 47, 48, 48, 49, 50, 50, 51, 52,
  52, 53, 54, 55, 56, 57, 57, 58, 59, 60,
  61, 62, 63, 64, 65, 66, 67, 67, 68, 70,
  71, 72, 72, 73, 74, 76, 77, 78, 79, 79,
  80, 81, 83, 84, 84, 86, 86, 87, 87, 88,
  88, 89, 89, 90, 90,127,127,127
]
/* eslint-enable */

/* eslint-disable */
const USE_DRIVE_SPEED_TABLE = true

function driveSpeedExact (value) {
  if (value > 127) {
    value = 127
  } else if (value < -127) {
    value = -127
  }
  return value
}

function driveSpeedLUT (value) {
  value = driveSpeedExact(value)
  return (((value > 0) - (value < 0)) * driveSpeedTable[Math.abs(value)])
}

function driveSpeed (value) {
  if (USE_DRIVE_SPEED_TABLE) {
    return driveSpeedLUT(value)
  } else {
    return driveSpeedExact(value)
  }
}

const controlUpdate = debounce(function (x, y) {
  return this.updateSpeed(x, y)
}, 25, { maxWait: 100 })

export default {
  name: 'Control',
  components: {
    QBtn,
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
  props: {
    config: Object
  },
  data () {
    return {
      control: null,
      x: 0,
      y: 0,
      ne: 0,
      nw: 0,
      se: 0,
      sw: 0
    }
  },
  mounted () {
    const control = nipplejs.create({
      zone: this.$refs.control,
      mode: 'semi', // 'dynamic' for multitouch
      color: 'white',
      catchDistance: 150
      // multitouch: true,
      // maxNumberOfNipples: 2
    })
    control.on('move', (event, data) => this.move(event, data))
    control.on('end', (event) => this.end(event))
    this.control = Vue.nonreactive(control)
  },
  methods: {
    end (event) {
      this.updateCancel()
      this.$nextTick(() => {
        this.updateSpeed(0, 0)
      })
      // this.x = 0
      // this.y = 0
      // this.updateImmediate()
      // window.setTimeout(this.end, 2000)
    },
    move (event, data) {
      const x = Math.ceil(((data.position.x - data.instance.position.x) / 50) * 127)
      const y = Math.ceil(((data.instance.position.y - data.position.y) / 50) * 127)
      // console.log('calling update: %o %o', this.x, this.y)
      this.update(x, y)
    },
    updateImmediate (ne, nw, se, sw) {
      this.ne = ne
      this.nw = nw
      this.se = se
      this.sw = sw
      if (this.config && this.config.drive) {
        const drive = this.config.drive
        if (drive.ne && drive.nw && drive.se && drive.sw) {
          return this.$apollo.mutate({
            mutation: gql`mutation WriteDriveMotors($value: [MotorCommand]!) {
              writeAllMotors(value: $value)
            }`,
            variables: {
              value: [
                { index: drive.ne.index, value: this.ne },
                { index: drive.nw.index, value: this.nw },
                { index: drive.se.index, value: this.se },
                { index: drive.sw.index, value: this.sw }
              ]
            }
          }).then((result) => {
            console.log('result: %o', result)
          })
        }
      }
      return false
    },
    updateSpeed (x, y) {
      if (x === this.x && y === this.y) {
        return false
      }
      this.x = x
      this.y = y
      const ne = driveSpeed(this.y - this.x)
      const nw = driveSpeed(this.y + this.x)
      const se = driveSpeed(this.y - this.x)
      const sw = driveSpeed(this.y + this.x)
      return this.updateImmediate(ne, nw, se, sw)
    },
    update: controlUpdate,
    updateCancel: controlUpdate.cancel
  }
}
</script>

<style scoped>
.debug {
  color: white;
  font-family: monospace;
  font-size: 12pt;
}

.zone-container {
  margin: 0;
  padding: 0;
  margin-left: auto;
  margin-right: auto;
}

.zone {
  background-color: #000000;
  display: block;
  position: absolute;
  width: 100%;
  height: 100%;
  left: 0;
}
</style>
