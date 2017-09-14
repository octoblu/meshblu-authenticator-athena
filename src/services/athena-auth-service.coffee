_       = require 'lodash'
jwt     = require 'jsonwebtoken'
validator = require 'validator'
debug   = require('debug')('meshblu-authenticator-athena:athena-auth-service')

class AthenaAuthService
  constructor: ({ @REDIRECT_URL, @athenaRequestService }) ->
    throw new Error 'AthenaAuthService: requires REDIRECT_URL' unless @REDIRECT_URL?
    throw new Error 'AthenaAuthService: requires athenaRequestService' unless @athenaRequestService?

  getAccessToken: ({ code }, callback) =>
    return callback @_createError('Invalid code from athena', 422) unless code?
    @athenaRequestService.request {
      method: 'POST'
      pathname: '/core/connect/token'
      form:
        code: code
        grant_type: 'authorization_code'
        redirect_uri: @REDIRECT_URL
    }, (error, body) =>
      return callback error if error?
      if _.isEmpty body
        return callback @_createError 'Empty response from create access token', 404
      callback null, body

  getUserInfo: ({ code }, callback) =>
    @getAccessToken { code }, (error, result) =>
      return callback error if error?
      userInfo = @_getUserInfoFromToken result
      return callback @_createError 'Unable to get user info' unless userInfo?
      callback null, userInfo

  _createError: (message='Internal Server Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _getUserInfoFromToken: ({ id_token, access_token } = {}) =>
    return unless id_token?
    decoded_token = jwt.decode id_token
    debug 'decoded_token', decoded_token
    return null unless decoded_token?
    userInfo = @_createSaneUserInfo { decoded_token, id_token, access_token }
    debug 'got user info', userInfo
    return userInfo

  _createSaneUserInfo: ({ decoded_token, id_token, access_token }) =>
    userInfo = _.cloneDeep decoded_token
    userInfo.id_token = id_token
    userInfo.access_token = access_token
    delete userInfo.iat
    if _.isEmpty(userInfo.email) && validator.isEmail userInfo.name
      userInfo.email = userInfo.name
      delete userInfo.name
    if _.isEmpty(userInfo.name)
      userInfo.name = "#{userInfo.given_name} #{userInfo.family_name}"
    return _.mapValues userInfo, @_getValueFromToken

  _getValueFromToken: (value) =>
    value = true if value in ['True', 'true']
    value = false if value in ['False', 'false']
    return value

module.exports = AthenaAuthService
