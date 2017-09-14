basicAuth = require 'basic-auth-connect'

class Router
  constructor: ({ @authenticatorController }) ->
    throw new Error 'Router: requires authenticatorController' unless @authenticatorController?

  route: (app) =>
    app.get '/authenticate', @authenticatorController.authenticate
    app.get '/authenticate/callback', @authenticatorController.ensureUser
    app.get '/logout', @authenticatorController.logout
    app.get '/logout/callback', @authenticatorController.logoutUser
    app.post '/logout/callback', @authenticatorController.logoutUser

module.exports = Router
