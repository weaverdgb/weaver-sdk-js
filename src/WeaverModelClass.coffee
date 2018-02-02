cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
cjson       = require('circular-json')
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

  constructor: (nodeId)->
    super(nodeId, @model.getGraph())


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

    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")
    if not @totalClassDefinition.relations[key]?
      throw new Error("#{@className} model is not allowed to have the #{key} relation")

    @totalClassDefinition.relations[key].key or key


  getRanges: (key)->
    addSubRange = (range, ranges = []) =>
      for className, definition of @definition.classes
        if definition.super is range
          ranges.push(className)
          # Follow again for this subclass
          addSubRange(className, ranges)

      ranges

    totalRanges = []
    for range in @_getRangeKeys(key)
      totalRanges.push(range)
      totalRanges = totalRanges.concat(addSubRange(range))

    totalRanges

  lookUpModelKey: (databaseKey)->
    return key for key, obj of @totalClassDefinition.relations when obj? and obj.key? and obj.key is databaseKey
    key


  _getRangeKeys: (key)->
    return [] if not @totalClassDefinition.relations?
    range = @totalClassDefinition.relations[key].range
    if _.isArray(range)
      range
    else
      _.keys(range)

  getToRanges: (key, to)->
    defs = []
    if to instanceof Weaver.ModelClass
      defs = (def.id().split(":")[1] for def in to.nodeRelation(@model.getMemberKey()).all())
    else  
      defs = (def.id().split(":")[1] for def in to.relation(@model.getMemberKey()).all())
    ranges = @getRanges(key)
    (def for def in defs when def in ranges)

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
    key = @_getAttributeKey(field)
    return null if not key?
    super(key)

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
        throw new Error("Attribute #{key} is required for a #{@className} model")

    # Check cardinality on relations
    for key, relation of @totalClassDefinition.relations when relation?.card?
      [min, max] = relation.card
      current = @relation(key).all().length

      if current < min
        throw new Error("Relation #{key} requires a minimum of #{min} relations for a #{@className} model. Currently #{current} is set.")
      else if max isnt 'n' and current > max
        throw new Error("Relation #{key} allows a maximum of #{max} relations for a #{@className} model. Currently #{current} is set.")

    super(project)


module.exports = WeaverModelClass
