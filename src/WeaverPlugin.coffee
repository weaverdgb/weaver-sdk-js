Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()

class WeaverPlugin

  constructor: (serverObject) ->
    @._name        = serverObject.name
    @._version     = serverObject.version
    @._author      = serverObject.author
    @._description = serverObject.description
    @._functions   = serverObject.functions

    # Parse functions
    serverObject.functions.forEach((f) =>
      @[f.name] = (args...) ->

        # Build payload from arguments
        payload = {}
        for r, index in f.require
          payload[r] = args[index]

        CoreManager.executePluginFunction(f.route, payload)
    )

  @load: (name) ->
    CoreManager.getPlugin(name)

  # Parse for easy reading
  printFunctions: ->
    functions = []
    for f in @_functions
      args = ""
      args += r + "," for r in f.require
      args = args.slice(0, -1) # Remove last comma
      functions.push("#{f.name}(#{args})")

    functions

  getPluginName: ->
    @_name

  getPluginVersion: ->
    @_version

  getPluginAuthor: ->
    @_author

  getPluginDescription: ->
    @_description

  @list: ->
    CoreManager.listPlugins()


module.exports = WeaverPlugin
