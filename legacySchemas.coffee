MESSAGE_SCHEMA =
  type: 'object'
  properties: serial_out:
    type: 'string'
    required: true
OPTIONS_SCHEMA =
  type: 'object'
  properties:
    port:
      type: 'string'
      required: true
    baud:
      type: 'integer'
      required: true
      enum: [
        115200
        57600
        38400
        19200
        9600
        4800
        2400
        1800
        1200
        600
        300
        200
        150
        134
        110
        75
        50
      ]
      default: 57600
    delimiter:
      type: 'string'
      default: '\\n'

module.exports = {
  messageSchema: MESSAGE_SCHEMA
  optionsSchema: OPTIONS_SCHEMA
}
