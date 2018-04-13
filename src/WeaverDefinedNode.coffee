Weaver      = require('./Weaver')
Promise     = require('bluebird')

class WeaverDefinedNode extends Weaver.Node

  constructor: (@nodeId, @graph) ->
    super(@nodeId, @graph)

  getDefinitions: ->

    addSuperDefs = (def, defs = []) =>
      res = []
      [modelName, className] = def.split(':')
      if not @model.modelMap[modelName]?  
        console.log "#{modelName} in #{modelName}:#{className} is not available on model #{@model.definition.name}"
      definition = @model.modelMap[modelName].definition.classes[className]
      if definition.super?
        superClassName = @model.getNodeNameByKey(definition.super)
        res.push(superClassName) if superClassName not in defs
        res = res.concat(addSuperDefs(superClassName, defs))
        res
      else
        res

    defs = []
    defs = (def.id() for def in @relation(@model.getMemberKey()).all())
    
    totalDefs = (def for def in defs)
    totalDefs = totalDefs.concat(addSuperDefs(def, defs)) for def in defs
    totalDefs
   

# Export
module.exports = WeaverDefinedNode
