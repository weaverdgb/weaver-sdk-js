# Libs
Promise = require('bluebird')

# Dependencies
CoreManager = require('./CoreManager')

# Main class exposing all features
class Weaver

  # Expose classes
  @Node     : require('./WeaverNode')
  Relation : require('./WeaverRelation')
  ACL      : require('./WeaverACL')
  Query    : require('./WeaverQuery')
  Error    : require('./WeaverError')

  version: ->
    require('../package.json').version

  @initialize: (@address) ->
    @coreManager = new CoreManager(@address)
    @coreManager.connect()

  @getCoreManager: ->
    console.log(@coreManager)
    @coreManager



# Export
module.exports = Weaver             # Node
#window.Weaver  = Weaver if window?  # Browser