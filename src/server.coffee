enableDestroy           = require 'server-destroy'
octobluExpress          = require 'express-octoblu'
session                 = require 'cookie-session'
cookieParser            = require 'cookie-parser'
Router                  = require './router'
AuthenticatorService    = require './services/authenticator-service'
AthenaService           = require './services/athena-service'
AuthenticatorController = require './controllers/authenticator-controller'

SESSION_SECRET='some-secret-that-does-not-really-matter'

class Server
  constructor: (options) ->
    { @logFn, @disableLogging, @port } = options
    { @meshbluConfig, @env, @privateKey } = options
    console.log 'server:constructor:options', options
    console.log 'server:constructor:meshbluConfig', meshbluConfig
    throw new Error 'Server: requires meshbluConfig' unless @meshbluConfig?
    throw new Error 'Server: requires env' unless @env?
    throw new Error 'Server: requires privateKey' unless @privateKey?

  address: =>
    @server.address()

  destroy: =>
    @server.destroy()

  run: (callback) =>
    app = octobluExpress { @logFn, @disableLogging }

    app.use cookieParser()
    app.use session @_sessionOptions()

    athenaService = new AthenaService @env
    authenticatorService = new AuthenticatorService {
      @meshbluConfig
      @privateKey
      athenaService
    }

    authenticatorController = new AuthenticatorController {
      authenticatorService
      athenaService
    }

    router = new Router {
      authenticatorController
    }

    router.route app

    @server = app.listen @port, callback
    enableDestroy @server

  stop: (callback) =>
    @server.close callback

  _sessionOptions: =>
    return {
      name: 'meshblu-authenticator-athena'
      secret: SESSION_SECRET
      maxAge: 60 * 60 * 1000
      sameSite: 'lax'
      overwrite: true
    }


module.exports = Server
