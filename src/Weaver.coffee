Promise = require('bluebird')

class Weaver

  constructor: ->

    if Weaver.weaver?
      throw new Error('Do not instantiate Weaver twice')

    Weaver.instance = @

    # Make Weaver objects available through the instance
    # FIXME: Should probably be done with a for loop or something
    @Node = Weaver.Node
    @ACL = Weaver.ACL
    @CoreManager = Weaver.CoreManager
    @History = Weaver.History
    @Plugin = Weaver.Plugin
    @Project = Weaver.Project
    @Query = Weaver.Query
    @Relation = Weaver.Relation
    @RelationNode = Weaver.RelationNode
    @Role = Weaver.Role
    @User = Weaver.User
    @Error = Weaver.Error
    @LegacyError = Weaver.LegacyError
    if !window?
      @File = Weaver.File

    @coreManager = new Weaver.CoreManager()
    @_connected  = false
    @_local      = false

  version: ->
    require('../package.json').version

  serverVersion: ->
    @coreManager.serverVersion()

  local: (routes) ->
    @_local = true
    @coreManager.local(routes)

  connect: (endpoint, options) ->
    @coreManager.connect(endpoint, options).then(=>
      @_connected = true
      @coreManager.updateLocalTimeOffset()
    )

  getCoreManager: ->
    @coreManager

  getUsersDB: ->
    @coreManager.getUsersDB()

  useProject: (project) ->
    @coreManager.currentProject = project

  currentProject: ->
    @coreManager.currentProject

  currentUser: ->
    @coreManager.currentUser

  signOut: ->
    @coreManager.signOutCurrentUser()

  # Sign in using username and password
  signInWithUsername: (username, password) ->
    @coreManager.signInUsername(username, password)

  # Sign in using a JSON webtoken
  signInWithToken: (authToken) ->
    @coreManager.signInToken(authToken)

  wipe: ->
    @coreManager.wipe()

  # Function is needed by the weaver-sdk-angular. This sets a callback
  # on the promise library for the digestion cycle to work.
  setScheduler: (fn) ->
    Promise.setScheduler(fn)

  # Returns the Weaver instance if instantiated. This should be called from
  # a static reference
  @getInstance: ->
    if(not @instance)
      throw new Error('Please instantiate Weaver before calling getInstance!')

    @instance

  # Returns the coremanager if Weaver is instantiated. This should be called from
  # a static reference
  @getCoreManager: ->
    @getInstance().getCoreManager()

# Export
module.exports = Weaver             # Node
window.Weaver  = Weaver if window?  # Browser

# Require Weaver objects after exporting Weaver to prevent circular dependency
# issues
module.exports.Node         = require('./WeaverNode')
module.exports.ACL          = require('./WeaverACL')
module.exports.CoreManager  = require('./CoreManager')
module.exports.History      = require('./WeaverHistory')
module.exports.Plugin       = require('./WeaverPlugin')
module.exports.Project      = require('./WeaverProject')
module.exports.Query        = require('./WeaverQuery')
module.exports.Relation     = require('./WeaverRelation')
module.exports.RelationNode = require('./WeaverRelationNode')
module.exports.Role         = require('./WeaverRole')
module.exports.User         = require('./WeaverUser')
module.exports.Error        = require('./WeaverError')
module.exports.LegacyError  = require('./Error')
if !window? # Prevent issues with WeaverFile when in browser
  module.exports.File       = require('./WeaverFile')
