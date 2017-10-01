export default class ConvexCode {
  constructor (events) {
    this.events = events
    this.built = false
    this.lines = []
  }

  build () {
    if (this.built === true) {
      return
    }
    if (this.events.length === 0 || this.events.length === 1) {
      this.motorStopAll()
      this.built = true
      return
    }
    const len = this.events.length
    for (let i = 0; i < len; i++) {
      const event = this.events[i]
      const nextEvent = this.events[i + 1]
      this.pushEvent(event)
      if (nextEvent) {
        let duration = nextEvent.ticks - event.ticks
        if (duration <= 25) {
          duration = 25
        }
        this.taskDelay(duration)
      } else {
        this.taskDelay(25)
      }
    }
    this.motorStopAll()
    this.built = true
  }

  push (line) {
    this.lines.push(line)
  }

  pushEvent (event) {
    ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'].forEach((index) => {
      const value = event[index]
      if (value !== null && value >= -127 && value <= 127) {
        this.motorSet(parseInt(index) + 1, value)
      }
    })
  }

  motorSet (index, value) {
    this.push(`vexMotorSet(kVexMotor_${index}, ${value});`)
  }

  motorStopAll () {
    this.push(`vexMotorStopAll();`)
  }

  taskDelay (milliseconds) {
    this.push(`vexSleep(${milliseconds});`)
  }

  toString () {
    this.build()
    return this.lines.join('\n')
  }
}
