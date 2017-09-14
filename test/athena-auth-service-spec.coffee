{describe,it,beforeEach,afterEach} = global
{expect}      = require 'chai'
jwt           = require 'jsonwebtoken'
shmock        = require '@octoblu/shmock'
enableDestroy = require 'server-destroy'
AthenaService = require '../src/services/athena-service'

describe 'AthenaAuthService', ->
  beforeEach ->
    @athena = shmock()
    enableDestroy @athena
    @sut = new AthenaService {
      ATHENA_URL   : "http://localhost:#{@athena.address().port}"
      REDIRECT_URL : 'http://example.com'
      CLIENT_ID    : 'some-client-id'
      CLIENT_SECRET: 'some-client-secret'
    }

  afterEach ->
    @athena.destroy()

  describe '->getAccessToken', ->
    describe 'when successful', ->
      beforeEach (done) ->
        clientAuth = new Buffer('some-client-id:some-client-secret').toString('base64')

        @tokenRequest = @athena.post '/core/connect/token'
          .set 'Authorization', "Basic #{clientAuth}"
          .set 'Content-Type', 'application/x-www-form-urlencoded'
          .send {
            code: 'some-code'
            grant_type: 'authorization_code'
            redirect_uri: 'http://example.com'
          }
          .reply 201, {
            id_token: 'some-id-token'
            access_token: 'some-access-token'
          }

        @sut.getAccessToken { code: 'some-code' }, (error, @result) =>
          return done error if error?
          done()

      it 'should yield an id_token and access_token', ->
        expect(@result).to.deep.equal {
          id_token: 'some-id-token'
          access_token: 'some-access-token'
        }

      it 'should get the token from athena', ->
        @tokenRequest.done()

  describe '->getUserInfo', ->
    describe 'when called with a JWT', ->
      beforeEach (done) ->
        clientAuth = new Buffer('some-client-id:some-client-secret').toString('base64')

        @id_token = jwt.sign({
          email: 'some-email'
          name: 'some-name'
          email_verified: 'True'
          given_name: 'some-first-name'
          family_name: 'some-last-name'
          ctx_auth_alias: 'some-alias'
        }, 'shhhhh')

        @tokenRequest = @athena.post '/core/connect/token'
          .set 'Authorization', "Basic #{clientAuth}"
          .set 'Content-Type', 'application/x-www-form-urlencoded'
          .send {
            code: 'some-code'
            grant_type: 'authorization_code'
            redirect_uri: 'http://example.com'
          }
          .reply 201, {
            id_token: @id_token
            access_token: 'some-access-token'
          }

        @sut.getUserInfo { code: 'some-code' }, (error, @userInfo) =>
          done error

      it 'should have the correct user info', ->
        expect(@userInfo).to.deep.equal {
          email: 'some-email'
          name: 'some-name'
          email_verified: true
          id_token: @id_token
          access_token: 'some-access-token'
          given_name: 'some-first-name'
          family_name: 'some-last-name'
          ctx_auth_alias: 'some-alias'
        }

      it 'should call get the access token', ->
        @tokenRequest.done()

    describe 'when called with a WEIRD JWT (thinclient fix)', ->
      beforeEach (done) ->
        clientAuth = new Buffer('some-client-id:some-client-secret').toString('base64')

        @id_token = jwt.sign({
          name: 'some-email@example.com'
          email_verified: 'False'
          given_name: 'some-first-name'
          family_name: 'some-last-name'
          ctx_auth_alias: 'some-alias'
        }, 'shhhhh')

        @tokenRequest = @athena.post '/core/connect/token'
          .set 'Authorization', "Basic #{clientAuth}"
          .set 'Content-Type', 'application/x-www-form-urlencoded'
          .send {
            code: 'some-code'
            grant_type: 'authorization_code'
            redirect_uri: 'http://example.com'
          }
          .reply 201, {
            id_token: @id_token
            access_token: 'some-access-token'
          }

        @sut.getUserInfo { code: 'some-code' }, (error, @userInfo) =>
          done error

      it 'should have the correct user info', ->
        expect(@userInfo).to.deep.equal {
          email: 'some-email@example.com'
          name: 'some-first-name some-last-name'
          email_verified: false
          id_token: @id_token
          access_token: 'some-access-token'
          given_name: 'some-first-name'
          family_name: 'some-last-name'
          ctx_auth_alias: 'some-alias'
        }

      it 'should call get the access token', ->
        @tokenRequest.done()
