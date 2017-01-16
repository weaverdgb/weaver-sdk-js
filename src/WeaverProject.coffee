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

  @useProject: (prj) ->
    new Promise((resolve, error) ->
      db = Weaver.getProjectsDB()
      db.clear()
      db.insert(prj)
      resolve()
    )

  @getActiveProject: ->
    Weaver.getProjectsDB().findOne()

Weaver.Project = WeaverProject
module.exports = WeaverProject

