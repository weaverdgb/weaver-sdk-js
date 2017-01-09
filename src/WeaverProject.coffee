WeaverNode = require('./WeaverNode')
Weaver     = require('./Weaver')

class WeaverProject
  constructor: (@name, @id) ->

  @create: ->
    Weaver.getCoreManager().createProject(@).then( => @)

  @delete: ->
    Weaver.getCoreManager().deleteProject(@)

  @list: ->
    Weaver.getCoreManager().listProjects().then((res) ->
      console.log(res)
      res
    )

Weaver.Project = WeaverProject
module.exports = WeaverProject

