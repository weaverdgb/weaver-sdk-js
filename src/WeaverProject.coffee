cuid        = require('cuid')
WeaverRoot  = require('./WeaverRoot')

class WeaverProject extends WeaverRoot

  getClass: ->
    WeaverProject
  @getClass: ->
    WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name, @projectId) ->
    @name = @name or 'unnamed'
    @projectId = @projectId or cuid()
    @_stored = false

  id: ->
    @projectId

  create: ->
    @getWeaver().getCoreManager().createProject(@projectId, @name).then(=>  # Wait till project gets read
      new Promise((resolve) =>

        checkReady = =>
          @getWeaver().getCoreManager().readyProject(@projectId).then((ready) =>
            if not ready
              setTimeout(checkReady, WeaverProject.READY_RETRY_TIMEOUT) # Check again after some time
            else
              resolve()
          )

        checkReady()
      )
    )
    .then(=> # Project is ready
      @_stored = true
      @
    )

  destroy: ->
    super().then(=>
      @getWeaver().getCoreManager().deleteProject(@id())
    )

  getAllNodes: (attributes)->
    @getWeaver().getCoreManager().getAllNodes(attributes, @id())

  getAllRelations:->
    @getWeaver().getCoreManager().getAllRelations(@id())

  destroy: ->
    @getWeaver().getCoreManager().deleteProject(@id())

  wipe: ->
    @getWeaver().getCoreManager().wipe(@id())

  getACL: ->
    @getWeaver().getCoreManager().getACL(@projectId)

  @list: ->
    @getWeaver().getCoreManager().listProjects()

module.exports = WeaverProject

