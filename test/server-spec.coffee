{describe,it,beforeEach,afterEach} = global
{expect} = require 'chai'
{ privateKey } = require './dumb-private-key.json'
Server   = require '../src/server'

describe 'Server', ->
  beforeEach (done) ->
    @sut = new Server {
      meshbluConfig :
        hostname: 'localhost'
        protocol: 'http'
        port: 0xd00d
        resolveSrv: false
        uuid: '...'
        token: '...'
      port       : undefined
      privateKey : privateKey
      env        :
        ATHENA_URL: '...'
        REDIRECT_URL: '...'
        CLIENT_ID: '...'
        CLIENT_SECRET: '...'
    }

    @sut.run (@error) => done()

  afterEach ->
    @sut.destroy()

  it 'should not have an error', ->
    expect(@error).to.not.exist
