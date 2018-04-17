cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
_           = require('lodash')

class WeaverModelClass extends Weaver.Node

  @classId: ->
    "#{@definition.name}:#{@className}"

  # Make a node member of this class
  @addMember: (node)->
    if node instanceof WeaverModelClass
      node.nodeRelation(@model.definition.member).addInGraph(@getNode(), node.getGraph())
    else
      node.relation(@model.definition.member).addInGraph(@getNode(), node.getGraph())

  # Construct a node representing this ModelClass
  @getNode: ->
    Weaver.Node.getFromGraph(@classId(), @model.getGraph())

  constructor: (nodeId, graph)->
    super(nodeId, graph)

    # Add type definition to model class
    classId = @constructor.classId()
    classNode = Weaver.Node.getFromGraph(classId, @model.getGraph())
    @nodeRelation(@model.getMemberKey()).addInGraph(classNode, @model.getGraph())

  getInherit: ->
    @nodeRelation(@model.getInheritKey()).all()

  getInheritKey: ->
    console.warn('Deprecated function WeaverModelClass.getInheritKey() used. Ask the model, not this modelclass.')
    @model.getInheritKey()

  getMember: ->
    @nodeRelation(@model.getMemberKey()).all()

  getPrototype: ->
    console.warn('Deprecated function WeaverModelClass.getPrototype() used. Use WeaverModelClass.getMember().')
    @getMember()

  # Returns a definition where all super definitions are collected into


  # override
  _loadRelationFromQuery: (key, instance, nodeId, graph)->
    if @totalClassDefinition.relations[key]?
      @relation(key).add(instance, nodeId, false, graph)
    else
      @nodeRelation(key).add(instance, nodeId, false, graph)



  _getAttributeKey: (field) ->

    if not @totalClassDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")
    if not @totalClassDefinition.attributes[field]?
      throw new Error("#{@className} model is not allowed to have the #{field} attribute")

    @totalClassDefinition.attributes[field].key or field

  _getRelationKey: (key) ->

    if key is @model.getInheritKey()
      return key
    if key is @model.getMemberKey()
      return key

    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")
    if not @totalClassDefinition.relations[key]?
      throw new Error("#{@className} model is not allowed to have the #{key} relation")

    @totalClassDefinition.relations[key].key or key





  getRanges: (key)->

    addSubRange = (range, ranges = []) =>

      for modelName, modelObject of @model.modelMap
        for className, definition of modelObject.definition.classes
          if definition.super?
            superClassName = @model.getNodeNameByKey(definition.super)
            if superClassName is range
              ranges.push("#{modelName}:#{className}")
              # Follow again for this subclass
              addSubRange("#{modelName}:#{className}", ranges)

      ranges

    totalRanges = []
    for rangeKey in @_getRangeKeys(key)
      totalRanges.push(rangeKey)
      totalRanges = totalRanges.concat(addSubRange(rangeKey))

    totalRanges

  lookUpModelKey: (databaseKey)->
    return key for key, obj of @totalClassDefinition.relations when obj? and obj.key? and obj.key is databaseKey
    databaseKey


  _getRangeKeys: (key)->
    return [] if not @totalClassDefinition.relations?
    ranges = @totalClassDefinition.relations[key].range
    ranges = _.keys(ranges) if not _.isArray(ranges)
    (range for range in ranges)

  getDefinitions: ->

    addSuperDefs = (def, defs = []) =>
      res = []
      modelName = @model.definition.name
      className = def
      if def.indexOf(':') > -1
        [modelName, className] = def.split(':')
      if not @model.modelMap[modelName]?
        console.log "#{modelName} in #{modelName}:#{className} is not available on model #{@model.definition.name}"
      definition = @model.modelMap[modelName].definition.classes[className]
      if definition.super?
        superClassName = @model.modelMap[modelName].getNodeNameByKey(definition.super)
        res.push(superClassName) if superClassName not in defs
        res = res.concat(addSuperDefs(superClassName, defs))
        res
      else
        res

    defs = []
    defs = (def.id() for def in @.nodeRelation(@model.getMemberKey()).all())

    totalDefs = (def for def in defs when def.indexOf(':') > -1)
    totalDefs = totalDefs.concat(addSuperDefs(def, defs)) for def in defs when def.indexOf(':') > -1
    totalDefs

  getToRanges: (key, to)->
    if to instanceof Weaver.ModelClass
      defs = to.getDefinitions()
      ranges = @getRanges(key)
      (def for def in defs when def in ranges)
    else if to instanceof Weaver.DefinedNode
      defs = to.getDefinitions()
      ranges = @getRanges(key)
      (def for def in defs when def in ranges)
    else
      []

  attributes: ->
    return {} if not @totalClassDefinition.attributes?

    attributes = {}
    for key, definiton of @totalClassDefinition.attributes
      attributes[key] = @get(key)

    attributes

  relations: ->
    return {} if not @totalClassDefinition.relations?

    relations = {}
    for key, definiton of @totalClassDefinition.relations
      relations[key] = @relation(key)

    relations

  nodeGet: (args...)->
    super.get(args...)

  get: (field) ->
    try
      super(@_getAttributeKey(field))
    catch
      undefined

  nodeSet: (args...)->
    super.set(args...)

  set: (field, value) ->
    key = @_getAttributeKey(field)
    return null if not key?
    super(key, value)

  nodeRelation: (args...)->
    Weaver.Node.prototype.relation.call(@, args...)

  relation: (key) ->
    modelKey = key
    relationKey = @_getRelationKey(key)
    model = @model
    className = @className
    definition = @definition
    relationDefinition = @totalClassDefinition.relations[key]
    classRelation = class extends Weaver.ModelRelation

      constructor: (parent, key)->
        super(parent, key)
        @modelKey           = modelKey
        @model              = model
        @className          = className
        @definition         = definition
        @relationDefinition = relationDefinition

    super(relationKey, classRelation)

  save: (project) ->
    # Check required attributes
    for key, attribute of @totalClassDefinition.attributes when attribute.required
      if not @get(key)?
        console.warn("Attribute #{key} is required for a #{@className} model")

    # Check cardinality on relations
    for key, relation of @totalClassDefinition.relations when relation?.card?
      [min, max] = relation.card
      current = @relation(key).all().length

      if current < min
        console.warn("Relation #{key} requires a minimum of #{min} relations for a #{@className} model. Currently #{current} is set.")
      else if max isnt 'n' and current > max
        console.warn("Relation #{key} allows a maximum of #{max} relations for a #{@className} model. Currently #{current} is set.")

    super(project)


module.exports = WeaverModelClass
