_                 = require 'lodash'
url               = require 'url'
request           = require 'request'
debug             = require('debug')('meshblu-authenticator-athena:athena-request-service')

class AthenaRequestService
  constructor: ({ @REDIRECT_URL, @CLIENT_ID, @CLIENT_SECRET, @ATHENA_URL }) ->
    throw new Error 'AthenaRequestService: requires REDIRECT_URL' unless @REDIRECT_URL?
    throw new Error 'AthenaRequestService: requires CLIENT_ID' unless @CLIENT_ID?
    throw new Error 'AthenaRequestService: requires CLIENT_SECRET' unless @CLIENT_SECRET?
    throw new Error 'AthenaRequestService: requires ATHENA_URL' unless @ATHENA_URL?

  formatUrl: ({ pathname, query }) =>
    urlParts = url.parse @ATHENA_URL, true
    urlParts.pathname = pathname
    urlParts.query = query if query?
    urlParts.slashes = true
    return url.format urlParts

  request: ({ method, pathname, form, json, qs }, callback) =>
    request {
      uri: @formatUrl { pathname }
      method,
      auth:
        username: @CLIENT_ID
        password: @CLIENT_SECRET
      form
      json
      qs
    }, (error, response, body) =>
      statusCode = _.get response, 'statusCode'
      debug 'request', { method, pathname, error, statusCode, body }
      return callback error if error?
      body = @_tryJSON body
      debug 'request parsed body', body
      if statusCode >= 500
        return callback @_createError "AthenaError code: #{statusCode}", statusCode
      if statusCode == 404
        return callback()
      if statusCode >= 400
        message = _.get body, 'Message'
        return callback @_createError "AthenaUserError: #{statusCode} #{message}", statusCode
      callback null, body

  _createError: (message='Internal Server Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _tryJSON: (str) =>
    try return JSON.parse str
    return str || {}

module.exports = AthenaRequestService
