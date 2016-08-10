_               = require 'lodash'
async           = require 'async'
{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-serial:index')
serialport      = require 'serialport'
{ SerialPort }  = serialport

class Connector extends EventEmitter
  constructor: ->
    debug 'Serial constructed'
    @emitSerial = _.throttle @_emitSerial, 200, { leading: true }

  isOnline: (callback) =>
    callback null, running: !!@client

  close: (callback) =>
    @cleanup (error) =>
      @emitError error
      callback error

  onConfig: (device={}) =>
    { options } = device
    @cleanupIfChanged options, (error) =>
      return @emitError error if error?
      @setOptions options
      @connectToClient (error) =>
        return console.error error if error?
        debug 'connected'

  setOptions: (options={}) =>
    { @port, @baud, delimiter } = options
    @baud ?= 9600
    delimiter ?= "\\n"
    @delimiter = delimiter.replace(/\\n/g, "\n").replace(/\\r/g, "\r").replace(/\\d/g, "\d").replace(/\\t/g, "\t")

  writeSerial: (serial_out, callback) =>
    @connectToClient (error) =>
      callback error if error?
      debug 'connected'
      debug 'writing to serial_out'
      @client.write serial_out
      callback null

  connectToClient: (callback=->) =>
    debug 'connecting to client'
    return callback() if @client?
    return callback new Error('Missing Port') unless @port?
    testFn = =>
      return !!@client
    waitFn = (done) =>
      debug 'waiting to connect'
      @getPorts (error, @ports) =>
        return done error if error?
        return done new Error("#{@port} port not available") unless @port in @ports
        @connect()
        _.delay done, 5000
    async.until testFn, waitFn, callback

  connect: =>

    debug 'connecting to port', @port
    @client = new SerialPort @port, {
      baudrate: @baud,
      parser: serialport.parsers.readline @delimiter
    }
    @client.on 'open', =>
      @client.on 'data', @emitSerial

  getPortsAndEmit: (callback) =>
    @getPorts (error, ports) =>
      callback error, { ports }

  getPorts: (callback) =>
    debug 'getting ports'
    serialport.list (error, ports) =>
      return callback error if error?
      found = _.map ports, 'comName'
      debug 'ports found', found
      callback null, found

  cleanupIfChanged: (newOptions={}, callback)=>
    debug 'cleanup if changed'
    { port, baud, delimiter } = newOptions
    return @cleanup callback if @port? && @port != port
    return @cleanup callback if @baud? && @baud != baud
    return @cleanup callback if @delimiter? && @delimiter != delimiter
    return callback()

  cleanup: (callback) =>
    return callback() unless @client?
    @client.close (error) =>
      @client = null
      callback error

  _emitSerial: (data) =>
    @emit 'message',
      devices: [ '*' ]
      topic: 'serial-in'
      payload:
        serial_in: data.toString()
        raw: data

  emitError: (error) =>
    return unless error?
    console.error error.message
    @emit 'message', {
      devices: ['*']
      topic: 'error'
      payload: {
        error: error.message
      }
    }

  start: (device, callback) =>
    debug 'started'
    @onConfig device
    callback()

module.exports = Connector
