Weaver      = require('./Weaver')
Promise     = require('bluebird')

class WeaverDefinedNode extends Weaver.Node

  constructor: (@nodeId, @graph) ->
    super(@nodeId, @graph)

  getNodeNameByKey: (model, dotPath) ->
    [first, rest...] = dotPath.split('.')
    return "#{model.definition.name}:#{dotPath}" if rest.length is 0
    return @getNodeNameByKey(model.includes[first], rest.join('.')) if model.includes[first]?
    return null

  getDefinitions: ->

    addSuperDefs = (def, defs = []) =>
      res = []
      [modelName, className] = def.split(':')
      if not @model.modelMap[modelName]?  
        console.log "#{modelName} in #{modelName}:#{className} is not available on model #{@model.definition.name}"
      definition = @model.modelMap[modelName].definition.classes[className]
      if definition.super?
        superClassName = @getNodeNameByKey(@model, definition.super)
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
