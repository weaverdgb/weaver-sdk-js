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
    @ACL         = require('./WeaverACL')
    @Role        = require('./WeaverRole')
    @User        = require('./WeaverUser')
    if window?
      @FileBrowser      = require('./WeaverFileBrowser')
    else
      @File      = require('./WeaverFile')
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
    @coreManager.connect(endpoint)

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


# Export
weaver = new Weaver()
module.exports = weaver             # Node
window.Weaver  = weaver if window?  # Browser
