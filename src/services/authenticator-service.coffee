_                       = require 'lodash'
moment                  = require 'moment'
MeshbluHttp             = require 'meshblu-http'
{ DeviceAuthenticator } = require 'meshblu-authenticator-core'
debug                   = require('debug')('meshblu-authenticator-athena:authenticator-service')
DEFAULT_PASSWORD        = 'no-need-for-this'

class AuthenticatorService
  constructor: ({ meshbluConfig, privateKey, @athenaService }) ->
    console.log 'AuthService:constructor:meshbluConfig', meshbluConfig
    console.log 'AuthService:constructor:privateKey', privateKey
    throw new Error 'AuthenticatorService: requires meshbluConfig' unless meshbluConfig?
    throw new Error 'AuthenticatorService: requires privateKey' unless privateKey?
    throw new Error 'AuthenticatorService: requires athenaService' unless @athenaService?
    @authenticatorName = 'Meshblu Authenticator Athena'
    @authenticatorUuid = meshbluConfig.uuid
    throw new Error 'AuthenticatorService: requires an authenticator uuid' unless @authenticatorUuid?
    @meshbluHttp = new MeshbluHttp meshbluConfig
    @meshbluHttp.setPrivateKey privateKey
    @deviceModel = new DeviceAuthenticator {
      @authenticatorUuid
      @authenticatorName
      @meshbluHttp
    }

  fetchDevice: ({ uuid }, callback) =>
    return callback null unless uuid # could be an empty string
    @meshbluHttp.device uuid, callback

  logoutUser: ({ uuid }, callback) =>
    return callback null unless uuid # could be an empty string
    query = {
      $set:
        'user.loggedOutAt': moment().utc().toJSON()
      $unset:
        'user.id_token': true
        'user.access_token': true
    }
    @meshbluHttp.updateDangerously uuid, query, callback

  revokeToken: ({ uuid, token }, callback) =>
    return callback null unless uuid # could be an empty string
    return callback null unless token # could be an empty string
    @meshbluHttp.revokeToken uuid, token, callback

  _createError: (message='Internal Server Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _createSearchId: ({ userInfo, domain }) =>
    email = @_lowerCase userInfo.email
    domain = @_lowerCase domain
    return "#{@authenticatorUuid}:#{domain}:#{email}"

  _createUserDevice: ({ userInfo, searchId, domain }, callback) =>
    { email, name } = userInfo
    debug 'create device', { email }
    email = @_lowerCase email
    domain = @_lowerCase domain
    query = {}
    query['meshblu.search.terms'] = { $in: [searchId] }
    @deviceModel.create {
      query: query
      data: { email, name, domain, type: 'smartspaces-authenticator-athena:user' }
      user_id: "#{domain}:#{email}"
      secret: DEFAULT_PASSWORD
    }, (error, device) =>
      return callback error if error?
      uuid = _.get device, 'uuid'
      @_updateUserInfo { userInfo, uuid, searchId }, callback

  _findUserDeviceUuid: ({ searchId }, callback) =>
    query = {}
    query['meshblu.search.terms'] = { $in: [searchId] }
    @deviceModel.findVerified { query, password: DEFAULT_PASSWORD }, (error, device) =>
      return callback error if error?
      callback null, _.get device, 'uuid'

  _generateToken: ({ uuid }, callback) =>
    debug 'generate token', uuid
    @meshbluHttp.generateAndStoreToken uuid, callback

  _lowerCase: (str='') =>
    return str.toLowerCase()

  _maybeCreateDevice: ({ userInfo, domain }, callback) =>
    searchId = @_createSearchId { userInfo, domain }
    debug 'maybe create device', { searchId }
    @_findUserDeviceUuid { searchId }, (error, uuid) =>
      return callback error if error?
      return @_createUserDevice { userInfo, domain, searchId }, callback unless uuid?
      @_updateUserInfo { userInfo, uuid, domain, searchId }, callback

  _updateUserInfo: ({ userInfo, uuid, domain, searchId }, callback) =>
    user = _.pick userInfo, 'id_token', 'name', 'email', 'given_name', 'family_name'
    user.updatedAt = moment().utc().toJSON()
    user.loggedOutAt = null
    { email, name } = user
    email = @_lowerCase email
    domain = @_lowerCase domain
    query =
      $addToSet: { 'meshblu.search.terms': searchId }
      $set: { user, domain, email, name, type: 'smartspaces-authenticator-athena:user' }
    @meshbluHttp.updateDangerously uuid, query, (error) =>
      return callback error if error?
      callback null, uuid

module.exports = AuthenticatorService
