Weaver  = require('./Weaver')

class WeaverPlugin

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
        payload[r] = args[f.require.length + index] for r, index in f.optional

        # Execute by route and payload
        Weaver.getCoreManager().executePluginFunction(f.route, payload)
    )

  # Load given plugin from server
  @load: (name) ->
    Weaver.getCoreManager().getPlugin(name)

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
    Weaver.getCoreManager().listPlugins()

module.exports = WeaverPlugin
