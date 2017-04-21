cuid        = require('cuid')
Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()

class WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name, @projectId) ->
    @name = @name or 'unnamed'
    @projectId = @projectId or cuid()
    @_stored = false

  id: ->
    @projectId

  create: ->
    CoreManager.createProject(@projectId, @name).then(=>  # Wait till project gets read
      new Promise((resolve) =>

        checkReady = =>
          CoreManager.readyProject(@projectId).then((project) =>
            if not project.ready
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
      CoreManager.deleteProject(@id())
    )

  getAllNodes: (attributes)->
    CoreManager.getAllNodes(attributes, @id())

  getAllRelations:->
    CoreManager.getAllRelations(@id())

  destroy: ->
    CoreManager.deleteProject(@id())

  wipe: ->
    CoreManager.wipe(@id())

  getACL: ->
    CoreManager.getACL(@projectId)

  @list: ->
    CoreManager.listProjects()

module.exports = WeaverProject

