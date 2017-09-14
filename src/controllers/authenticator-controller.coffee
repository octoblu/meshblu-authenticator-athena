_     = require 'lodash'
url   = require 'url'
debug = require('debug')('meshblu-authenticator-athena:authenticator-controller')

class AuthenticatorController
  constructor: ({ @authenticatorService, @athenaService }) ->
    throw new Error 'AuthenticatorController: authenticatorService' unless @authenticatorService?
    throw new Error 'AuthenticatorController: athenaService' unless @athenaService?

  authenticate: (request, response) =>
    { callbackUrl } = request.query
    unless domain?
      error = new Error 'Missing domain in query string'
      error.code = 422
      response.sendError error
      return
    request.session.callbackUrl = callbackUrl
    response.redirect @athenaService.formatAuthUrl({ domain })

  ensureUser: (request, response) =>
    { code } = request.query
    { callbackUrl, domain } = request.session
    debug 'ensureUser start', { code, callbackUrl }
    @authenticatorService.ensureUser { code }, (error, user) =>
      debug 'ensureUser done', { error, user }
      return response.sendError(error) if error?
      { uuid, token } = user
      debug 'sucessful', callbackUrl, user
      request.session.callbackUrl = null
      request.session.uuid = uuid
      return response.send user unless callbackUrl?
      response.redirect @_formatSuccessUrl { callbackUrl, uuid, token }

  logout: (request, response) =>
    { callbackUrl, uuid, token } = request.query
    debug '->logout', { callbackUrl, uuid, token }
    @authenticatorService.revokeToken { uuid, token }, (error) =>
      debug 'fetchDevice->revokeToken', error if error?
      return response.sendError error if error?
      @authenticatorService.fetchDevice { uuid }, (error, device) =>
        debug 'fetchDevice->error', error if error?
        return response.sendError error if error?
        debug '->logout', { id_token, device }
        id_token = _.get device, 'user.id_token'
        request.session.callbackUrl = callbackUrl
        request.session.uuid = uuid
        logoutUri = @athenaService.formatLogoutUrl { id_token }
        debug '->logout', { logoutUri }
        response.redirect logoutUri

  logoutUser: (request, response) =>
    { callbackUrl, uuid } = request.session
    debug '->logoutUser', { callbackUrl, uuid }
    request.session.callbackUrl = null
    request.session.uuid = null
    @authenticatorService.logoutUser { uuid }, (error) =>
      debug '->logoutUser->error', error if error?
      return response.sendError error if error?
      unless callbackUrl?
        debug '->logoutUser no callbackUrl'
        return response.sendStatus(204)
      debug '->logoutUser', callbackUrl
      response.redirect callbackUrl

  _formatSuccessUrl: ({ callbackUrl, uuid, token }) =>
    uriParams = url.parse callbackUrl, true
    delete uriParams.search
    uriParams.query ?= {}
    uriParams.query.uuid = uuid
    uriParams.query.token = token
    uriParams.slashes = true
    return url.format uriParams

module.exports = AuthenticatorController
