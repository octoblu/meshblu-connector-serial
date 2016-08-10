http = require 'http'

class GetPorts
  constructor: ({@connector}) ->
    throw new Error 'GetPorts requires connector' unless @connector?

  do: ({data}, callback) =>

    @connector.getPortsAndEmit (err, data) =>
      return callback @_userError(404, 'Error finding ports', err) if err
      metadata =
        code: 200
        status: http.STATUS_CODES[200]

      callback null, {metadata, data}

  _userError: (code, message) =>
    error = new Error message
    error.code = code
    return error

module.exports = GetPorts
