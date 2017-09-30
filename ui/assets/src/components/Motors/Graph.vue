<template lang="pug">
.layout-padding
  div(ref="graph")
  //- template(v-if="motors")
  //- template(v-if="motorsReady")
    q-card
      q-list(separator)
        motor-item(v-for="motor of motors", :key="motor.id", :color="motorColors[motor.index]", :index="motor.index", :motor-id="motor.id", :value="motor.value", :editable="motorsEdit")
        q-item(tag="label")
          q-item-side
            q-toggle(color="warning", v-model="motorsEdit")
          //- q-item-side(icon="warning", color="warning")
          q-item-main
            q-item-tile(label) Manual Override
      q-card-separator
      q-card-actions
        q-btn(color="negative", icon="stop", @click="stopAllMotors()") Stop All Motors
        q-btn(color="warning", icon="warning", @click="reverseAllMotors()") Reverse All Motors
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
// import {
//   debounce
// } from 'lodash'
// import d3 from 'd3'
import Rickshaw from 'rickshaw'
import Vue from 'vue'

// const MotorColors = [
//   '#F44336', // [ 0] Red 500
//   '#E91E63', // [ 1] Pink 500
//   '#9C27B0', // [ 2] Purple 500
//   '#673AB7', // [ 3] Deep Purple 500
//   '#3F51B5', // [ 4] Indigo 500
//   '#2196F3', // [ 5] Blue 500
//   '#03A9F4', // [ 6] Light Blue 500
//   '#00BCD4', // [ 7] Cyan 500
//   '#009688', // [ 8] Teal 500
//   '#4CAF50', // [ 9] Green 500
//   '#8BC34A', // [10] Light Green 500
//   '#CDDC39', // [11] Lime 500
//   '#FFEB3B', // [12] Yellow 500
//   '#FFC107', // [13] Amber 500
//   '#FF9800', // [14] Orange 500
//   '#FF5722', // [15] Deep Orange 500
//   '#795548', // [16] Brown 500
//   '#9E9E9E', // [17] Grey 500
//   '#607D8B' // [18] Blue Grey 500
// ]

// const Motor10Colors = [
//   MotorColors[6], // light-blue
//   MotorColors[4], // indigo
//   MotorColors[2], // purple
//   MotorColors[0], // red
//   MotorColors[16], // brown
//   MotorColors[14], // orange
//   MotorColors[12], // yellow
//   MotorColors[10], // light-green
//   MotorColors[8], // teal
//   MotorColors[17] // grey
// ]

const materialScheme = [
  '#00BCD4',
  '#2196F3',
  '#3F51B5',
  '#9C27B0',
  '#F44336',
  '#FF9800',
  '#FFC107',
  '#CDDC39',
  '#4CAF50',
  '#009688'
]

export default {
  name: 'Graph',
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
      graph: null,
      graphed: false,
      ready: false,
      timer: null
    }
  },
  watch: {
    motors (motors) {
      if (motors) {
        this.ready = true
        if (!this.graphed) {
          this.graphed = true
          const palette = new Rickshaw.Color.Palette({
            scheme: materialScheme
          })
          const graphData = motors.map((motor) => {
            return {
              color: palette.color(),
              // data: [motor.value],
              name: `motor ${motor.index}`
            }
          })
          const graph = new Rickshaw.Graph({
            // element: d3.select(this.$refs.graph),
            element: this.$refs.graph,
            width: 900,
            height: 500,
            renderer: 'line',
            interpolation: 'step',
            stroke: true,
            preserve: true,
            stack: false,
            min: -127,
            max: 127,
            series: new Rickshaw.Series.FixedDuration(graphData, undefined, {
              timeInterval: 500,
              maxDataPoints: 600,
              timeBase: new Date().getTime() / 1000
            })
          })
          this.graph = Vue.nonreactive(graph)
          // debugger
          // this.graph.render()
          if (this.timer !== null) {
            window.clearInterval(this.timer)
            this.timer = null
          }
          this.timer = window.setInterval(() => this.update(), 500)
        }
      }
    }
  },
  methods: {
    update () {
      const data = this.motors.reduce((acc, motor) => {
        acc[`motor ${motor.index}`] = motor.value
        return acc
      }, {})
      // const data = {
      //   one: Math.floor(Math.random() * 40) + 120
      // }
      // const randInt = Math.floor(Math.random() * 100)
      // data.two = (Math.sin((i++) / 40) + 4) * (randInt + 400)
      // data.three = randInt + 300
      this.graph.series.addData(data)
      this.graph.render()
    }
  },
  beforeDestroy () {
    if (this.timer !== null) {
      window.clearInterval(this.timer)
      this.timer = null
    }
  }
}
</script>
