WeaverRoot  = require('./WeaverRoot')

class WeaverPlugin extends WeaverRoot

  getClass: ->
    WeaverPlugin
  @getClass: ->
    WeaverPlugin

  constructor: (serverObject) ->
    @._name        = serverObject.name
    @._version     = serverObject.version
    @._author      = serverObject.author
    @._description = serverObject.description
    @._functions   = serverObject.functions

    # Parse functions that will be accessible from @
    serverObject.functions.forEach((f) =>
      @[f.name] = (args...) ->

        # Build payload from arguments based on function require
        payload = {}
        payload[r] = args[index] for r, index in f.require

        # Execute by route and payload
        @getWeaver().getCoreManager().executePluginFunction(f.route, payload)
    )

  # Load given plugin from server
  @load: (name) ->
    @getWeaver().getCoreManager().getPlugin(name)

  # Parse plugin functions for easy reading
  printFunctions: ->

    # Example: The function add with require x and y becomes add(x,y)
    prettyFunction = (f) ->
      args = ""
      args += r + "," for r in f.require
      args = args.slice(0, -1) # Remove last comma
      "#{f.name}(#{args})"

    (prettyFunction(f) for f in @_functions)

  getPluginName: ->
    @_name

  getPluginVersion: ->
    @_version

  getPluginAuthor: ->
    @_author

  getPluginDescription: ->
    @_description

  @list: ->
    @getWeaver().getCoreManager().listPlugins()

module.exports = WeaverPlugin
