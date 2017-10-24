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
          try
            if payload.type isnt "STREAM"
              routeHandler.handleRequest(route, {payload: JSON.parse(payload or "{}")}, res)
            else
              routeHandler.handleRequest(route, {payload}, res)
          catch error
            res.fail("Invalid json payload")
            return
      )
    )

  GET: (path) ->
    $.handler[path]()

  POST: (path, body) ->
    $.handler[path](body)

module.exports = LocalController
