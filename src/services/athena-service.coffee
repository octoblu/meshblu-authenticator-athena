_                      = require 'lodash'
url                    = require 'url'
AthenaAuthService      = require './athena-auth-service'
AthenaRequestService   = require './athena-request-service'
debug                  = require('debug')('meshblu-authenticator-athena:athena-service')

class AthenaService
  constructor: ({ @REDIRECT_URL, @CLIENT_ID, @CLIENT_SECRET, @ATHENA_URL }) ->
    throw new Error 'AuthenticatorController: requires REDIRECT_URL' unless @REDIRECT_URL?
    throw new Error 'AuthenticatorController: requires CLIENT_ID' unless @CLIENT_ID?
    throw new Error 'AuthenticatorController: requires CLIENT_SECRET' unless @CLIENT_SECRET?
    throw new Error 'AuthenticatorController: requires ATHENA_URL' unless @ATHENA_URL?
    @athenaRequestService = new AthenaRequestService {
      @REDIRECT_URL
      @CLIENT_ID
      @CLIENT_SECRET
      @ATHENA_URL
    }
    @athenaAuthService = new AthenaAuthService { @REDIRECT_URL, @athenaRequestService }

  formatAuthUrl: ({ domain }={}) =>
    options = {
      pathname: '/core/connect/authorize'
      query:
        client_id: @CLIENT_ID
        scope: 'openid email profile ctx_principal_aliases'
        response_type: 'code'
        redirect_uri: @_getRedirectUri { pathname: '/authenticate/callback' }
    }
    if domain?
      acr_values = []
      acr_values.push "tenant:#{_.kebabCase(domain)}"
      acr_values.push "product:octoblu"
      options.query.acr_values = _.join(acr_values, ' ')
      options.query.credential_type = 'client'
    return @athenaRequestService.formatUrl options

  formatLogoutUrl: ({ id_token }) =>
    return @athenaRequestService.formatUrl {
      pathname: '/core/connect/endsession'
      query:
        id_token_hint: id_token
        post_logout_redirect_uri: @_getRedirectUri { pathname: '/logout/callback' }
    }

  getAccessToken: ({ code }, callback) =>
    @athenaAuthService.getAccessToken { code }, callback

  getUserInfo: ({ code }, callback) =>
    @athenaAuthService.getUserInfo { code }, callback

  _createError: (message='Internal Server Error', code=500) =>
    error = new Error message
    error.code = code
    return error

  _getRedirectUri: ({ pathname }) =>
    urlParts = url.parse @REDIRECT_URL, true
    urlParts.pathname = pathname
    urlParts.slashes = true
    return url.format urlParts

module.exports = AthenaService
