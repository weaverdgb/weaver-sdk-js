# Libs
Promise = require('bluebird')

# Dependencies
CoreManager = require('./CoreManager')

# Main class exposing all features
class Weaver

  constructor: ->
    @coreManager = new CoreManager()
    @_connected  = false
    @_local      = false

  _registerClasses: ->
    @Node        = require('./WeaverNode')
    @Relation    = require('./WeaverRelation')
    @SystemNode  = require('./WeaverSystemNode')
    @Project     = require('./WeaverProject')
    @Query       = require('./WeaverQuery')
    @Relation    = require('./WeaverRelation')
    @ACL         = require('./WeaverACL')
    @Role        = require('./WeaverRole')
    @User        = require('./WeaverUser')
    @File        = require('./WeaverFile')
    @Error       = require('./WeaverError')
    @LegacyError = require('./Error')         # TODO: Clean out in another PR

  version: ->
    require('../package.json').version

  local: (bus) ->
    @_registerClasses()
    @_local = true
    @coreManager.local(bus)

  connect: (endpoint) ->
    @_registerClasses()
    @_connected = true
    @coreManager.connect(endpoint)

  getCoreManager: ->
    @coreManager

  getUsersDB: ->
    @coreManager.getUsersDB()

  useProject: (project) ->
    @coreManager.currentProject = project

  currentProject: ->
    @coreManager.currentProject


# Export
weaver = new Weaver()
module.exports = weaver             # Node
window.Weaver  = weaver if window?  # Browser
