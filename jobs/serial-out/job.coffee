http = require 'http'

class SerialOut
  constructor: ({@connector}) ->
    throw new Error 'SerialOut requires connector' unless @connector?

  do: ({data}, callback) =>
    return callback @_userError(422, 'data.example is required') unless data?.example?

    metadata =
      code: 200
      status: http.STATUS_CODES[200]

    callback null, {metadata, data}

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = SerialOut
