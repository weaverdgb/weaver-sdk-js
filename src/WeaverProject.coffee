Weaver = require('./Weaver')

class WeaverProject extends Weaver.SystemNode

  @READY_RETRY_TIMEOUT: 200

  # TODO: Pass name instead of nodeId, nodeId must not be able to be given
  constructor: (@nodeId) ->
    super(@nodeId)
    @_created = false

  create: ->
    coreManager = Weaver.getCoreManager()
    id = @id()

    coreManager.createProject(id).then(->  # Wait till project gets read
      new Promise((resolve) ->

        checkReady = ->
          coreManager.readyProject(id).then((res) ->
            if not res.ready
              setTimeout(checkReady, WeaverProject.READY_RETRY_TIMEOUT) # Check again after some time
            else
              resolve()
          )

        checkReady()
      )
    )
    .then(=> # Project is ready, create the node
      @_created = true
      @set("type", "project")
      @save()
    )

  save: ->
    if not @_created
      Promise.reject({error: -1, message: 'Should call create() first before saving'})
    else
      super()

  destroy: ->
    super().then(=>
      Weaver.getCoreManager().deleteProject(@id())
    )

  wipe: ->
    coreManager = Weaver.getCoreManager()
    coreManager.wipe(@id())

  @load: (nodeId) ->
    super(nodeId, WeaverProject)

  @get: (nodeId) ->
    super(nodeId, WeaverProject)

  @list: ->
    new Weaver.Query("$SYSTEM").equalTo("type", "project").find()

module.exports = WeaverProject

