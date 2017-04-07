# Libs
Promise = require('bluebird')

# Dependencies
CoreManager = require('./CoreManager')

# Main class exposing all features
class Weaver

  getClass: ->
    Weaver
  @getClass: ->
    Weaver

  constructor: ->

    Weaver.ACL.weaver = @
    Weaver.CoreManager.weaver = @
    if Weaver.File
      Weaver.File.weaver = @
    Weaver.History.weaver = @
    Weaver.Node.weaver  = @
    #    Weaver.Model.weaver = @
    Weaver.Node.weaver = @
    Weaver.Plugin.weaver = @
    Weaver.Project.weaver = @
    Weaver.Query.weaver = @
    Weaver.Role.weaver = @
    Weaver.User.weaver = @

    @coreManager = new CoreManager()
    @_connected  = false
    @_local      = false

  version: ->
    require('../package.json').version

  serverVersion: ->
    @coreManager.serverVersion()

  local: (routes) ->
    @_local = true
    @coreManager.local(routes)

  connect: (endpoint) ->
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

  signIn: (username, password) ->
    @coreManager.signInUser(username, password)

  wipe: ->
    @coreManager.wipe()

  # Function is needed by the weaver-sdk-angular. This sets a callback
  # on the promise library for the digestion cycle to work.
  setScheduler: (fn) ->
    Promise.setScheduler(fn)



# Those hold a reference to the weaver instance
Weaver.ACL         = require('./WeaverACL')
Weaver.CoreManager = require('./CoreManager')
if !window?
  Weaver.File      = require('./WeaverFile') # avoiding problems on browsers trying to load node's fs stuff

Weaver.History     = require('./WeaverHistory')
Weaver.Node        = require('./WeaverNode')
#Weaver.Model       = require('./WeaverModel')
Weaver.Plugin      = require('./WeaverPlugin')
Weaver.Project     = require('./WeaverProject')
Weaver.Query       = require('./WeaverQuery')
Weaver.Role        = require('./WeaverRole')
Weaver.User        = require('./WeaverUser')

# Those do not hold a reference
Weaver.Relation    = require('./WeaverRelation')
Weaver.Error       = require('./WeaverError')
Weaver.LegacyError = require('./Error')

# Export
#weaver = new Weaver()
#module.exports = weaver             # Node
#window.Weaver  = weaver if window?  # Browser
module.exports = Weaver             # Node
window.Weaver  = Weaver if window?  # Browser

