cuid        = require('cuid')
Weaver  = require('./Weaver')

class WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name, @projectId, @acl, @_stored = false) ->
    @name = @name or 'unnamed'
    @projectId = @projectId or cuid()

  id: ->
    @projectId

  create: ->
    coreManager = Weaver.getCoreManager()
    coreManager.createProject(@projectId, @name)
    .then((acl) =>  # Wait till project gets read
      @acl = acl
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

  executeZip: (filename) ->
    Weaver.getCoreManager().executeZippedWriteOperations(@id(), filename)

  destroy: ->
    super().then(=>
      Weaver.getCoreManager().deleteProject(@id())
    )

  freeze: ->
    Weaver.getCoreManager().freezeProject(@id())
    
  unfreeze: ->
    Weaver.getCoreManager().unfreezeProject(@id())

  getAllNodes: (attributes)->
    Weaver.getCoreManager().getAllNodes(attributes, @id())

  getAllRelations:->
    Weaver.getCoreManager().getAllRelations(@id())
    
  rename: (name) ->
    renamed = Weaver.getCoreManager().nameProject(@id(), name)
    @name = name
    renamed

  getSnapshot: (zipped = false) ->
    Weaver.getCoreManager().snapshotProject(@id(), zipped)

  clone: (id, name) ->
    Weaver.getCoreManager().cloneProject(@id(), id, name).then((acl) ->
      new Weaver.Project(name, id, acl, true)
    )

  destroy: ->
    Weaver.getCoreManager().deleteProject(@id())

  wipe: ->
    Weaver.getCoreManager().wipeProject(@id())

  getACL: ->
    Weaver.getCoreManager().getACL(@projectId)

  compatibleApps: ->
    Weaver.getCoreManager().getCompatibleApps(@projectId)

  @list: ->
    Weaver.getCoreManager().listProjects().then((list) ->
      ( new Weaver.Project(p.name, p.id, p.acl, true) for p in list )
    )

module.exports = WeaverProject
