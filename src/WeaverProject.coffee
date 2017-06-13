cuid        = require('cuid')
Weaver  = require('./Weaver')

class WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name, @projectId, @_stored = false) ->
    @name = @name or 'unnamed'
    @projectId = @projectId or cuid()

  id: ->
    @projectId

  create: ->
    coreManager = Weaver.getCoreManager()
    coreManager.createProject(@projectId, @name)
    .then(=>  # Wait till project gets read
      new Promise((resolve) =>

        checkReady = =>
          coreManager.readyProject(@projectId).then((project) =>
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
      Weaver.getCoreManager().deleteProject(@id())
    )

  getAllNodes: (attributes)->
    Weaver.getCoreManager().getAllNodes(attributes, @id())

  getAllRelations:->
    Weaver.getCoreManager().getAllRelations(@id())

  getSnapshot:->
    Weaver.getCoreManager().snapshotProject(@id())

  destroy: ->
    Weaver.getCoreManager().deleteProject(@id())

  wipe: ->
    Weaver.getCoreManager().wipeProject(@id())

  getACL: ->
    Weaver.getCoreManager().getACL(@projectId)

  @list: ->
    Weaver.getCoreManager().listProjects().then((list) ->
      ( new Weaver.Project(p.name, p.id, true) for p in list )
    )

module.exports = WeaverProject
