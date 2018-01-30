cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  @classId: ->
    "#{@definition.name}:#{@className}"

  @addMember: (node)->
    if node instanceof WeaverModelClass
      node.nodeRelation(@model.definition.member).addInGraph(@getNode(), node.getGraph())
    else
      node.relation(@model.definition.member).addInGraph(@getNode(), node.getGraph())

  @getNode: ->
    Weaver.Node.getFromGraph(@classId(), @model.getGraph())

  constructor: (nodeId)->
    super(nodeId, @model.getGraph())
    @totalClassDefinition = @_collectFromSupers()

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
  _collectFromSupers: ->
    addFromSuper = (classDefinition, totalDefinition = {attributes: {}, relations: {}}) =>

      # Start with supers so lower specifications override the super ones
      if classDefinition.super?
        superDefinition = @definition.classes[classDefinition.super]
        addFromSuper(superDefinition, totalDefinition)

      transfer = (source) ->
        totalDefinition[source][k] = v for k, v of classDefinition[source] if classDefinition[source]?

      transfer('attributes')
      transfer('relations')

      totalDefinition

    addFromSuper(@classDefinition)

  # override
  _loadRelationFromQuery: (key, instance, nodeId, graph)->
    @nodeRelation(key).add(instance, nodeId, false, graph)

  _getAttributeKey: (field) ->

    if not @totalClassDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")
    if not @totalClassDefinition.attributes[field]?
      throw new Error("#{@className} model is not allowed to have the #{field} attribute")

    @totalClassDefinition.attributes[field].key or field

  # Returns null if the model did not define this
  _getRelationKey: (key) ->

    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")
    if not @totalClassDefinition.relations[key]?
      throw new Error("#{@className} model is not allowed to have the #{key} relation")

    @totalClassDefinition.relations[key].key or key

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
    super(@_getAttributeKey(field))

  nodeSet: (args...)->
    super.set(args...)

  set: (field, value) ->
    key = @_getAttributeKey(field)
    return null if not key?
    super(key, value)

  nodeRelation: (args...)->
    Weaver.Node.prototype.relation.call(@, args...)

  relation: (key) ->

    relationKey = @_getRelationKey(key)
    return null if not relationKey?

    # Based on the key, construct a specific Weaver.ModelRelation
    modelKey             = relationKey
    model                = @model
    relationDefinition   = @totalClassDefinition.relations[key]
    className            = @className
    definition           = @definition
    totalClassDefinition = @totalClassDefinition

    classRelation = class extends Weaver.ModelRelation
      constructor:(parent, key) ->
        super(parent, key)
        @modelKey           = modelKey
        @model              = model
        @className          = className
        @definition         = totalClassDefinition
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
