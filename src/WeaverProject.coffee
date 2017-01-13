WeaverNode = require('./WeaverNode')
Weaver     = require('./Weaver')

class WeaverProject
  constructor: (@name, @id) ->

  create: ->
    Weaver.getCoreManager().createProject(@).then((res) =>
      @id = JSON.parse(res).id
      @
    )

  delete: ->
    Weaver.getCoreManager().deleteProject(@)

  @list: ->
    Weaver.getCoreManager().listProjects().then((res) ->
      ( new WeaverProject(i.name, i.id) for i in res )
    )

Weaver.Project = WeaverProject
module.exports = WeaverProject

