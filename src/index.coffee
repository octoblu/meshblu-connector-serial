{EventEmitter}  = require 'events'
debug           = require('debug')('meshblu-connector-serial:index')
_               = require 'lodash'
serialport      = require 'serialport'
SerialPort      = serialport.SerialPort
schemas         = require '../schemas.json'

port = "COM4"
baud = 9600

class Serial extends EventEmitter
  constructor: ->
    debug 'Serial constructed'
    @options = {}
    @ports   = []
    @waiting = false

  isOnline: (callback) =>
    callback null, running: true

  close: (callback) =>
    debug 'on close'
    callback()

  onMessage: (message) =>
    return unless message?
    { topic, devices, fromUuid } = message
    return if '*' in devices
    return if fromUuid == @uuid
    debug 'onMessage', { topic }
    if !@serialPort
      error = new Error('no connected serialPort');
      debug 'error', error
      @emit 'error', error

    payload = message.payload || {}

    if payload.serial_out
      @serialPort.write payload.serial_out

  onConfig: (config) =>
    return unless config?
    debug 'on config', @uuid
    @cleanup (error) =>
      if error
        @emit 'error', error

      @setOptions config.options
      debug 'options', @options

      if !@options.port
        error = new Error 'port field is required'
        debug 'error', error
      else
        @openPort()

  openPort: () =>
    @getPorts (currentPorts) =>
      if (_.indexOf currentPorts, @options.port) != -1
        debug 'found port - trying to connect'
        throttleEmit = _.throttle(((data) =>
          debug 'throttled', data
          @emit 'message',
            devices: [ '*' ]
            payload: serial_in: data.toString()
        ), 200, leading: true)
        @serialPort = new SerialPort @options.port, {
          baudrate: @options.baud
          parser: serialport.parsers.readline(@options.delimiter)
        }
        @serialPort.on "open", () =>
          @serialPort.on 'data', throttleEmit

      else if !@waiting && !@serialPort?
        @waiting = true
        debug 'waiting for port to become available'
        setTimeout =>
          @openPort()
          @waiting = false
        , 15000

  setOptions: (options) =>
    @options = _.defaults options, {
      baud: 57600
      delimiter: "\\n"
    }
    @options.delimiter = @options.delimiter.replace(/\\n/g, "\n").replace(/\\r/g, "\r").replace(/\\d/g, "\d").replace(/\\t/g, "\t")

    if !@serialPort?
      @getPorts (newPorts) =>
        if @options.port? && (_.indexOf newPorts, @options.port) == -1
          newPorts.push(@options.port)
        schemas.schemas.configure.optionSchema.properties.options.properties.port.enum = newPorts
        if !(_.isEqual @ports, newPorts)
          @ports = newPorts
          debug 'setting', newPorts
          @emit 'update', schemas

  getPorts: (callback) =>
    serialport.list (err, ports) =>
      found = _.map ports, (port) =>
        port.comName
      debug 'ports found', found
      callback found


  cleanup: (callback) =>
    callback = callback || _.noop

    if!@serialport
      return callback()

    @serialPort.close (error) =>
      @serialPort = null
      callback error

  start: (device) =>
    { @uuid } = device
    debug 'started', @uuid
    # @emit 'update', schemas

module.exports = Serial
