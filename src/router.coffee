basicAuth = require 'basic-auth-connect'

class Router
  constructor: ({ @authenticatorController, @adminUsername, @adminPassword }) ->
    throw new Error 'Router: requires authenticatorController' unless @authenticatorController?
    throw new Error 'Router: requires adminUsername' unless @adminUsername?
    throw new Error 'Router: requires adminPassword' unless @adminPassword?

  route: (app) =>
    app.get '/authenticate', @authenticatorController.authenticate
    app.get '/authenticate/callback', @authenticatorController.ensureUser
    app.get '/logout', @authenticatorController.logout
    app.get '/logout/callback', @authenticatorController.logoutUser
    app.post '/logout/callback', @authenticatorController.logoutUser

module.exports = Router
