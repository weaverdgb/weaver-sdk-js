# Libs
Promise = require('bluebird')

# Dependencies
CoreManager = require('./CoreManager')

# Exposes classes and injects Weaver into it
expose: (name, Type) ->



# Main class exposing all features
class Weaver

  # Error: require('./../../weaver-commons-js/src/WeaverError')
  Error: require('weaver-commons').WeaverError

  version: ->
    require('../package.json').version

  initialize: (@address) ->
    @coreManager = new CoreManager(@address)
    @coreManager.connect()

  getCoreManager: ->
    @coreManager


# Export
weaver = new Weaver()
module.exports = weaver             # Node
window.Weaver  = weaver if window?  # Browser