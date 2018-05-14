cuid   = require('cuid')
Weaver = require('./Weaver')
Ops    = require('./Operation')

class WeaverProject

  @READY_RETRY_TIMEOUT: 200

  constructor: (@name, @projectId, @acl, @_stored = false, @projectMetadata = {}) ->
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

  isFrozen: ->
    Weaver.getCoreManager().isFrozenProject(@id())

  addMetadata: (bundleKey, key, data) ->
    @projectMetadata[key] = data
    Weaver.getCoreManager().addProjectMetadata(@id(), bundleKey, key, data)

  removeMetadata: (bundleKey, key) ->
    delete @projectMetadata[key]
    Weaver.getCoreManager().removeProjectMetadata(@id(), bundleKey, key)

  getMetadata: ->
    (value for key,value of @projectMetadata) # change this to have a call to the server ?

  getAllNodes: (attributes)->
    Weaver.getCoreManager().getAllNodes(attributes, @id())

  getAllRelations:->
    Weaver.getCoreManager().getAllRelations(@id())

  rename: (name) ->
    renamed = Weaver.getCoreManager().nameProject(@id(), name)
    @name = name
    renamed

  getSnapshot: (json=true, zipped=false, stored=false) ->
    Weaver.getCoreManager().snapshotProject(@id(), json, zipped, stored)

  getSnapshotGraph: (graphs=[], fromGraphs=[], toGraphs=[], json=true, zipped=false, stored=false) ->
    Weaver.getCoreManager().snapshotProjectGraph(@id(), graphs, fromGraphs, toGraphs, json, zipped, stored)

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

  @list: ->
    Weaver.getCoreManager().listProjects().then((list) ->
      ( new Weaver.Project(p.name, p.id, p.acl, true, p.apps) for p in list )
    )

  truncateGraph: (graph, removeNode) ->
    removeNode.save().then( ->
      Weaver.getCoreManager().executeOperations([ Ops.Graph(graph).truncate(removeNode.id(), removeNode.getGraph()) ])
    )

  redirectGraph: (sourceGraph, oldTargetGraph, newTargetGraph, dryrun = false, performPartial = false) ->
    Weaver.getCoreManager().redirectGraph(@id(), sourceGraph, oldTargetGraph, newTargetGraph, dryrun, performPartial)


module.exports = WeaverProject
