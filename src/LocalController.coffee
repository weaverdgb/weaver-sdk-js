Promise = require('bluebird')

$ = {}

class LocalController

  constructor: (routes) ->
    # We should never expose the routes
    $.routes   = routes
    $.handler  = {}

    res =
      success: (data) ->
        Promise.resolve(data)
      fail: (error) ->
        Promise.reject(error)

    for name, routeHandler of routes
      for route in routeHandler.allRoutes()
        $.handler[route] = (payload) ->
          routeHandler.handleRequest(route, {payload}, res)

  _emit: (key, payload) ->
    $.getBus().emit(key, {payload})

  GET: (path) ->
    $.handler[path]()

  POST: (path, body) ->
    $.handler[path](body)

module.exports = LocalController
