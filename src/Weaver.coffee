Promise = require('bluebird')
PubSub  = require('pubsub-js')

class Weaver

  constructor: (opts)->

    if Weaver.instance?
      throw new Error('Do not instantiate Weaver twice')

    Weaver.instance = @

    # Make Weaver objects available through the instance
    # FIXME: Should probably be done with a for loop or something
    @Node = Weaver.Node
    @NodeList = Weaver.NodeList
    @DefinedNode = Weaver.DefinedNode
    @ACL = Weaver.ACL
    @CoreManager = Weaver.CoreManager
    @History = Weaver.History
    @Project = Weaver.Project
    @Query = Weaver.Query
    @Narql = Weaver.Narql
    @Relation = Weaver.Relation
    @RelationNode = Weaver.RelationNode
    @Role = Weaver.Role
    @User = Weaver.User
    @Error = Weaver.Error
    @LegacyError = Weaver.LegacyError
    @Model = Weaver.Model
    @ModelClass = Weaver.ModelClass
    @ModelRelation = Weaver.ModelRelation
    @ModelQuery = Weaver.ModelQuery

    @_connected  = false
    @_local      = false

    # Default options
    @_ignoresOutOfDate = true
    @_unrecoverableRemove = false

    if opts?
      @setOptions(opts)

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

  disconnect: ->
    @coreManager.disconnect()

  getCoreManager: ->
    @coreManager

  useProject: (project) ->
    @coreManager.currentProject = project

  startTransaction: ->
    if @coreManager.currentTransaction?
      throw new Error("A transaction is already set, first commit or rollback that one")
    @coreManager.currentTransaction = new Weaver.Transaction()
    @coreManager.currentTransaction.begin()
    .then(=>
      @coreManager.currentTransaction
    )

  @useModel: (model) ->
    Weaver.getCoreManager().currentModel = model

  currentProject: ->
    @coreManager.currentProject

  @currentModel: ->
    Weaver.getCoreManager().currentModel

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
    @coreManager.wipeProjects()
    .then(=>
      @coreManager.destroyProjects()
    ).then(=>
      @coreManager.wipeUsers()
    )

  # Function is needed by the weaver-sdk-angular. This sets a callback
  # on the promise library for the digestion cycle to work.
  setScheduler: (fn) ->
    Promise.setScheduler(fn)

  setOptions: (opts)->
    @_ignoresOutOfDate = opts.ignoresOutOfDate if opts.ignoresOutOfDate?
    @_unrecoverableRemove = opts.unrecoverableRemove if opts.unrecoverableRemove?

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

  # Shout a message to other connected clients
  @shout: (message) ->
    @getCoreManager().shout(message)

  # Listen to shouted messages
  @sniff: (callback) ->
    Weaver.subscribe("socket.shout", callback)


  # Expose PubSub
  @subscribe:             PubSub.subscribe
  @unsubscribe:           PubSub.unsubscribe
  @publish:               PubSub.publish
  @clearAllSubscriptions: PubSub.clearAllSubscriptions

# Export
module.exports = Weaver # Node

# Require Weaver objects after exporting Weaver to prevent circular dependency
# issues
module.exports.Node          = require('./WeaverNode')
module.exports.NodeList      = require('./WeaverNodeList')
module.exports.DefinedNode   = require('./WeaverDefinedNode')
module.exports.ACL           = require('./WeaverACL')
module.exports.CoreManager   = require('./CoreManager')
module.exports.History       = require('./WeaverHistory')
module.exports.Project       = require('./WeaverProject')
module.exports.Query         = require('./WeaverQuery')
module.exports.Narql         = require('./WeaverNarql')
module.exports.Relation      = require('./WeaverRelation')
module.exports.RelationNode  = require('./WeaverRelationNode')
module.exports.Role          = require('./WeaverRole')
module.exports.User          = require('./WeaverUser')
module.exports.Error         = require('./WeaverError')
module.exports.LegacyError   = require('./Error')
module.exports.Model         = require('./WeaverModel')
module.exports.ModelClass    = require('./WeaverModelClass')
module.exports.ModelRelation = require('./WeaverModelRelation')
module.exports.ModelQuery    = require('./WeaverModelQuery')
module.exports.Transaction   = require('./WeaverTransaction')
