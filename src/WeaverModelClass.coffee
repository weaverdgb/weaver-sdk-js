cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModelClass extends Weaver.Node

  @classId: ->
    "#{@definition.name}:#{@className}"

  @addMember: (node)->
    if node instanceof WeaverModelClass
      node.nodeRelation(@model.definition.member).addInGraph(@asNode(), node.getGraph())
    else
      node.relation(@model.definition.member).addInGraph(@asNode(), node.getGraph())
    node.save()

  @asNode: ->
    Weaver.Node.getFromGraph(@classId(), @model.getGraph())

  constructor: (nodeId)->
    super(nodeId, @model.getGraph())
    @totalClassDefinition = @_collectFromSupers()

    # Add type definition to model class
    @relation(@model.getMemberKey()).addInGraph(Object.getPrototypeOf(@).asNode(), @model.getGraphName())    

  getInherit: ->
    @relation(@model.getInheritKey()).first()

  getMember: ->
    @relation(@model.getMemberKey()).first()

  getInheritKey: ->
    console.warn('Deprecated function WeaverModelClass.getInheritKey() used. Ask the model, not this modelclass.')
    @model.getInheritKey()


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

  _getAttributeKey: (field) ->
    if not @totalClassDefinition.attributes?
      throw new Error("#{@className} model is not allowed to have attributes")

    if not @totalClassDefinition.attributes[field]?
      throw new Error("Field #{field} is not valid on this #{@className} model")

    @totalClassDefinition.attributes[field].key or field

  _getRelationKeys: (key) ->
    if not @totalClassDefinition.relations?
      throw new Error("#{@className} model is not allowed to have relations")

    if @totalClassDefinition.relations[key]?
      {
        model: key
        database: @totalClassDefinition.relations[key].key or key
      }
    else
      # May be a database relation
      modelKey = (j for j, i of @totalClassDefinition.relations when i? and i.key is key)

      if modelKey.length is 1
        {
          model: modelKey
          database: key
        }
      else
        throw new Error("Relation #{key} is not valid on this #{@className} model")

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

  get: (field) ->
    super(@_getAttributeKey(field))

  set: (field, value) ->
    super(@_getAttributeKey(field), value)

  relation: (key) ->
    # Return when using a special relation like the member relation
    return super(key) if [@model.getMemberKey()].includes(key)

    relationKeys = @_getRelationKeys(key)
    databaseKey = relationKeys.database

    # Based on the key, construct a specific Weaver.ModelRelation
    modelKey             = relationKeys.model
    model                = @model
    relationDefinition   = @totalClassDefinition.relations[relationKeys.model]
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

    super(databaseKey, classRelation)

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
