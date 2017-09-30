import {
  Socket
} from 'phoenix'

export const uri = (DEV) ? 'ws://127.0.0.1:4000/socket' : '/socket'

export const socket = new Socket(uri)

socket.connect()

export default socket
