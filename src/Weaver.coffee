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
    @Model       = require('./WeaverModel')
    @Relation    = require('./WeaverRelation')
    @Project     = require('./WeaverProject')
    @History     = require('./WeaverHistory')
    @Query       = require('./WeaverQuery')
    @Plugin      = require('./WeaverPlugin')
    @ACL         = require('./WeaverACL')
    @Role        = require('./WeaverRole')
    @User        = require('./WeaverUser')
    if !window?
      @File        = require('./WeaverFile') # avoiding problems on browsers trying to load node's fs stuff
    @Error       = require('./WeaverError')
    @LegacyError = require('./Error')         # TODO: Clean out in another PR

  version: ->
    require('../package.json').version

  serverVersion: ->
    @coreManager.serverVersion()

  local: (routes) ->
    @_registerClasses()
    @_local = true
    @coreManager.local(routes)

  connect: (endpoint) ->
    @_registerClasses()
    @_connected = true
    @coreManager.connect(endpoint).then(=>
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

  # args may be username/password or a token
  signIn: (args...) ->
    if args.length > 1
      username = args[0] || null
      password = args[1] || null
      return @coreManager.signInUser(username, password)
    else
      token = args[0] || null
      @coreManager.signInToken(token)

  status: ->
    commController: @coreManager.commController
    currentUser:    @currentUser()
    currentProject: @currentProject()

  wipe: ->
    @coreManager.wipe()

  # Function is needed by the weaver-sdk-angular. This sets a callback
  # on the promise library for the digestion cycle to work.
  setScheduler: (fn) ->
    Promise.setScheduler(fn)


# Export
weaver = new Weaver()
module.exports = weaver             # Node
window.Weaver  = weaver if window?  # Browser
