_              = require 'lodash'
envalid        = require 'envalid'
MeshbluConfig  = require 'meshblu-config'
SigtermHandler = require 'sigterm-handler'
Server         = require './src/server'

base64 = envalid.makeValidator (value) =>
  return throw new Error 'Expected a string' unless _.isString value
  return new Buffer(value, 'base64').toString('utf8')

envConfig = {
  PORT                     : envalid.num({ default: 80, devDefault: 5656 })
  AUTHENTICATOR_PRIVATE_KEY: base64 { desc: 'Base64 encoded private key for meshblu' }
  ATHENA_URL               : envalid.url({ default: 'https://accounts.cloud.com' })
  REDIRECT_URL             : envalid.url()
  CLIENT_ID                : envalid.str()
  CLIENT_SECRET            : envalid.str()
  ADMIN_USERNAME           : envalid.str()
  ADMIN_PASSWORD           : envalid.str()
}

class Command
  constructor: ->
    env = envalid.cleanEnv process.env, envConfig
    @serverOptions = {
      meshbluConfig : new MeshbluConfig().toJSON()
      port          : env.PORT
      privateKey    : env.AUTHENTICATOR_PRIVATE_KEY
      env           : env
    }

  panic: (error) =>
    console.error error.stack
    process.exit 1

  run: =>
    server = new Server @serverOptions
    server.run (error) =>
      return @panic error if error?

      {port} = server.address()
      console.log "AuthenticatorService listening on port: #{port}"

    sigtermHandler = new SigtermHandler()
    sigtermHandler.register server.stop


command = new Command()
command.run()
