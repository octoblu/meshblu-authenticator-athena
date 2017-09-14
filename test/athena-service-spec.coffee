{describe,it,beforeEach} = global
{expect}      = require 'chai'
url           = require 'url'
AthenaService = require '../src/services/athena-service'

describe 'AthenaService', ->
  beforeEach ->
    @sut = new AthenaService {
      ATHENA_URL   : 'http://some-athena.com'
      REDIRECT_URL : 'http://example.com'
      CLIENT_ID    : 'some-client-id'
      CLIENT_SECRET: 'some-client-secret'
    }

  describe '->formatAuthUrl', ->
    describe 'when called without an authDomain', ->
      it 'should have the correct url', ->
        expect(@sut.formatAuthUrl()).to.equal url.format {
          hostname: 'some-athena.com'
          protocol: 'http'
          slashes: true
          pathname: '/core/connect/authorize'
          query:
            client_id: 'some-client-id'
            scope: 'openid email profile ctx_principal_aliases'
            response_type: 'code'
            redirect_uri: 'http://example.com/authenticate/callback'
        }

    describe 'when called with an authDomain', ->
      it 'should have the correct url', ->
        expect(@sut.formatAuthUrl({ domain: 'test.octo.space' })).to.equal url.format {
          hostname: 'some-athena.com'
          protocol: 'http'
          slashes: true
          pathname: '/core/connect/authorize'
          query:
            client_id: 'some-client-id'
            scope: 'openid email profile ctx_principal_aliases'
            response_type: 'code'
            redirect_uri: 'http://example.com/authenticate/callback'
            acr_values: 'tenant:test-octo-space product:smartspaces'
            credential_type: 'client'
        }

  describe '->formatLogoutUrl', ->
    describe 'when called', ->
      it 'should have the correct url', ->
        options = { id_token: 'some-id-token', uuid: 'some-uuid' }
        expect(@sut.formatLogoutUrl(options)).to.equal url.format {
          hostname: 'some-athena.com'
          protocol: 'http'
          slashes: true
          pathname: '/core/connect/endsession'
          query:
            id_token_hint: 'some-id-token'
            post_logout_redirect_uri: 'http://example.com/logout/callback'
        }
