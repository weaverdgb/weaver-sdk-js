Promise = require('bluebird')

$ = {}

class LocalController

  constructor: (routes) ->
    # We should never expose the routes
    $.routes   = routes
    $.handler  = {}

    (handler for name, handler of routes).forEach((routeHandler) =>
      routeHandler.allRoutes().forEach((route) =>
        res =
          success: (data) ->
            Promise.resolve(data)
          fail: (error) ->
            Promise.reject(error)

        $.handler[route] = (payload) ->
          routeHandler.handleRequest(route, {payload}, res)
      )
    )

  GET: (path) ->
    $.handler[path]()

  POST: (path, body) ->
    $.handler[path](body)

module.exports = LocalController
