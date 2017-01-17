WeaverNode = require('./WeaverNode')
Weaver     = require('./Weaver')

class WeaverProject extends WeaverNode

  @READY_RETRY_TIMEOUT: 200

  constructor: (@nodeId) ->
    @_created = false
    super(@nodeId)

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
      @save()
    )

  save: ->
    if not @_created
      Promise.reject({error: -1, message: 'Should call create() first before saving'})
    else
      super(@)

  destroy: ->
    super(@).then(=>
      Weaver.getCoreManager().deleteProject(@id())
    )

  @list: ->
    Weaver.getCoreManager().listProjects().then((projects) ->
      # Set unnamed for projects without name
      p.name = 'Unnamed' for p in projects when not p.name?
      projects
    )

Weaver.Project = WeaverProject
module.exports = WeaverProject

