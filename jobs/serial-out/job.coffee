http = require 'http'

class SerialOut
  constructor: ({@connector}) ->
    throw new Error 'SerialOut requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.serial_out is required') unless data?.serial_out?

    @connector.writeSerial data.serial_out, (err) =>
      return callback @_userError(418, 'Some error?!', err) if err

      callback null

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = SerialOut
