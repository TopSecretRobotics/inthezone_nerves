<template lang="pug">
.layout-padding
  //- q-toggle(v-model="motorsEdit", label="Override Mode")
  //- div(ref="graph")
  //- ol
    li(v-for="motor of motors", :key="motor.id") {{ motor.value }} ({{ motor.ticks }})
  template(v-if="motorsReady")
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
      //- q-item(v-for="motorCommand of motorCommands", :key="motorCommand.id")
        //- q-item-side(icon="adjust")
        q-item-side
          q-chip(color="tertiary", pointing="right") {{ motorCommand.index }}
        q-item-main
          q-slider(v-model="motorCommand.value", :disable="!motorsEdit", :min="-127", :max="127", :step="1", label, square)
        q-item-side
          input(type="number", v-model="motorCommand.value", :disabled="!motorsEdit", :min="-127", :max="127", :step="1")
          //- q-input(v-model="motorCommand.value", type="number", :disable="!motorsEdit", :min="-127", :max="127", :step="1", :max-decimals="0")
          //- q-chip(color="tertiary", square) {{ motorCommand.value }}
    //- div
    //- <q-list>
    //-         <q-item>
    //-           <q-item-side icon="volume_down" />
    //-           <q-item-main>
    //-             <q-slider color="secondary" v-model="standard" :min="0" :max="50" label />
    //-           </q-item-main>
    //-           <q-item-side right icon="volume_up" />
    //-         </q-item>
    //-         <q-item>
    //-           <q-item-side icon="brightness_low" />
    //-           <q-item-main>
    //-             <q-slider color="orange" v-model="standard" :min="0" :max="50" label />
    //-           </q-item-main>
    //-           <q-item-side right icon="brightness_high" />
    //-         </q-item>
    //-         <q-item>
    //-           <q-item-side icon="mic" />
    //-           <q-item-main>
    //-             <q-slider color="black" v-model="standard" :min="0" :max="50" label />
    //-           </q-item-main>
    //-         </q-item>
    //-       </q-list>
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
// import Plotly from 'plotly.js'

import MotorItem from '@/Motors/MotorItem.vue'

class MotorAverage {
  constructor (capacity, value) {
    this.capacity = capacity
    this.values = []
    this.add(value)
  }

  add (value) {
    this.values.push(value)
    while (this.size > this.capacity) {
      this.values.shift()
    }
  }

  tick () {
    if (this.size > 1) {
      this.values.shift()
    }
  }

  get value () {
    if (this.size === 1) {
      return this.values[0]
    }
    let avg = Math.ceil(this.values.reduce((acc, value) => {
      return (acc + value) / 2
    }, 0))
    if (avg > 127) {
      avg = 127
    } else if (avg < -127) {
      avg = -127
    }
    return avg
  }

  get size () {
    return this.values.length
  }
}

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
  name: 'Overview',
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
      motorAverages: [],
      motorColors: Motor10ColorNames,
      motorCommands: [
        { index: 0, value: 0 },
        { index: 1, value: 0 },
        { index: 2, value: 0 },
        { index: 3, value: 0 },
        { index: 4, value: 0 },
        { index: 5, value: 0 },
        { index: 6, value: 0 },
        { index: 7, value: 0 },
        { index: 8, value: 0 },
        { index: 9, value: 0 }
      ],
      motorsEdit: false,
      motorsGraphed: false,
      motorsTimer: null,
      motorsReady: false
    }
  },
  watch: {
    motors (value) {
      if (value) {
        value.forEach((motor) => {
          if (typeof this.motorAverages[motor.index] === 'undefined') {
            this.motorAverages[motor.index] = new MotorAverage(5, motor.value)
          } else {
            this.motorAverages[motor.index].add(motor.value)
          }
          this.motorCommands.forEach((motorCommand) => {
            if (motorCommand.index === motor.index) {
              motorCommand.id = motor.id
              if (this.motorsEdit === false) {
                motorCommand.value = motor.value
              }
            }
          })
        })
        this.motorsReady = true
        // if (this.motorsGraphed === false && this.$refs.graph) {
        //   const graphTime = new Date()
        //   const graphData = value.map((motor) => {
        //     return {
        //       name: `motor ${motor.index}`,
        //       x: [graphTime],
        //       y: [motor.value],
        //       mode: 'lines',
        //       line: {
        //         color: Motor10Colors[motor.index],
        //         shape: 'vh'
        //       }
        //     }
        //   })
        //   // const prevTime = graphTime.setMinutes(graphTime.getMinutes() - 5)
        //   // const prevTime = graphTime.setMinutes(graphTime.getMinutes() + 0)
        //   // const nextTime = graphTime.setMinutes(graphTime.getMinutes() + 5)
        //   // console.log('prevTime: %o', prevTime)
        //   // console.log('nextTime: %o', nextTime)
        //   const graphLayout = {
        //     // xaxis: {
        //     //   type: 'date',
        //     //   range: [prevTime, nextTime]
        //     // },
        //     yaxis: {
        //       range: [-150, 150]
        //     }
        //   }
        //   Plotly.plot(this.$refs.graph, graphData, graphLayout)
        //   if (this.motorsTimer !== null) {
        //     window.clearInterval(this.motorsTimer)
        //     this.motorsTimer = null
        //   }
        //   this.motorsTimer = window.setInterval(() => this.updateGraph(), 500)
        //   this.motorsGraphed = true
        // }
      } else {
        this.motorAverages = []
        this.motorsReady = false
      }
    },
    motorsEdit (value) {
      if (!value && this.motors) {
        this.motors.forEach((motor) => {
          this.motorCommands.forEach((motorCommand) => {
            if (motorCommand.index === motor.index) {
              motorCommand.id = motor.id
              motorCommand.value = motor.value
            }
          })
        })
      }
    }
  },
  beforeDestroy () {
    if (this.motorsTimer !== null) {
      window.clearInterval(this.motorsTimer)
      this.motorsTimer = null
    }
  },
  methods: {
    reverseAllMotors: debounce(function () {
      this.motorsEdit = false
      return this.$apollo.mutate({
        mutation: gql`mutation ReverseAllMotors {
          reverseAllMotors
        }`
      })
    }, 250),
    stopAllMotors: debounce(function () {
      this.motorsEdit = false
      return this.$apollo.mutate({
        mutation: gql`mutation StopAllMotors {
          stopAllMotors
        }`
      })
    }, 250)
  }
  // methods: {
  //   updateGraph () {
  //     const time = new Date()
  //     const xdata = []
  //     const ydata = []
  //     const opts = []
  //     this.motors.forEach((motor) => {
  //       xdata.push([time])
  //       ydata.push([this.motorAverages[motor.index].value])
  //       opts.push(motor.index)
  //       this.motorAverages[motor.index].tick()
  //     })
  //     const data = {
  //       x: xdata,
  //       y: ydata
  //     }
  //     // const prevTime = time.setSeconds(time.getSeconds() - 5)
  //     // const nextTime = time.setSeconds(time.getSeconds() + 5)
  //     // const layout = {
  //     //   xaxis: {
  //     //     type: 'date',
  //     //     range: [prevTime, nextTime]
  //     //   }
  //     // }
  //     // Plotly.relayout(this.$refs.graph, layout)
  //     Plotly.extendTraces(this.$refs.graph, data, opts)
  //   }
  // }
}
</script>
