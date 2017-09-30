<template lang="pug">
table
  thead
    tr
      th ID
      th Time
      th Event
      th Type
      th Message
  tbody
    tr(v-for="data of events", :key="data.id")
      td {{ data.id }}
      td {{ data.timestamp }}
      td {{ data.event }}
      td {{ data.type }}
      td {{ data.message }}
</template>

<script>
import socket from 'src/configs/phoenix'

const eventId = (function () {
  let counter = 0
  return function () {
    return counter++
  }
})()

export default {
  name: 'Serial',
  data () {
    return {
      channel: socket.channel('serial:vex', {}),
      events: [],
      joined: false,
      joinError: null
    }
  },
  mounted () {
    this.$nextTick(() => {
      if (this.channel) {
        this.channel.join()
          .receive('ok', () => {
            this.joined = true
          })
          .receive('error', (resp) => {
            this.joined = false
            this.joinError = resp
          })
        this.channel.on('server', (data) => {
          data.id = eventId()
          data.time = new Date()
          data.timestamp = new Date(data.time.getTime()).toLocaleTimeString()
          if (data.message) {
            const [type, message] = data.message
            delete data.message
            data.type = type
            data.message = message
          }
          this.events.unshift(data)
        })
      }
    })
  },
  beforeDestroy () {
    if (this.channel) {
      this.channel.leave()
    }
  }
}
</script>
