# Libs
cuid = require('cuid')

# Helper functions
isObject = (object) ->
  Object.prototype.toString.call(object) is '[object Object]'

isReference = (object) ->
  object['_REF']?

isEntity = (value) ->
  typeof value.isEntity is 'function' and value.isEntity()

# Entity class exposing entity features
module.exports =
class Entity

  # Creates an Entity object from a native server object
  @create: (object) ->
    # Metadata
    type    = object['_META'].type
    fetched = object['_META'].fetched
    id      = object['_META'].id

    # Data
    data = {}
    data[key] = value for own key, value of object when key isnt '_META'

    new Entity(data, type, fetched, id)


  # Builds a deeply nested Entity object from a native server object
  @build: (object, weaver) ->
    references = {}

    # Create references
    register = (value) ->
      entity = Entity.create(value).weaver(weaver)
      references[entity.id()] = entity

      for key, value of entity when key isnt '$'
        if isObject(value) and not value['_REF']?
          register(value)

    register(object)

    # Follow and replace references
    for id, entity of references
      for key, value of entity when key isnt '$'
        if isObject(value)
          if isReference(value)
            entity[key] = references[value['_REF']]
          else
            entity[key] = references[value._META.id]

    # Return root entity
    return references[object._META.id]


  constructor: (data, type, fetched, id) ->
    # Generate id
    id = cuid() if not id?

    # Type is default root if not specified
    type = '_ROOT' if not type?

    # Locally created is always fetched
    fetched = true if not fetched?

    # Store any non-content of this entity under the $ variable
    @$ = {id, type, fetched}

    # Copy keys from data
    @[key] = value for key, value of data



  # Core
  # Get ID
  id: ->
    @$.id


  # Core
  # Get type
  type: ->
    @$.type


  # Core
  # Get all values that are not entities
  values: ->
    values = {}
    values[key] = value for own key, value of @ when key isnt '$' and key isnt isEntity(value)
    values


  # Core
  # Get all entities
  links: ->
    links = {}
    links[key] = value for own key, value of @ when isEntity(value)
    links


  # Core
  # Test wether this entity is fetched given the eagerness
  isFetched: (eagerness, visited) ->
    # Default
    eagerness = 1 if not eagerness?

    # Start with an empty map of visited entities
    visited = {} if not visited?

    # Early return because of visited before
    if visited[@id()]? and eagerness > -1 and visited[@id()] >= eagerness
      return true

    # It is exists, it must be fetched
    if eagerness is 0
      return true

    # If fetched
    if eagerness is 1 and @$.fetched
      return true

    # Eagerness -1 or larger than 1, so must at least be fetched
    if not @$.fetched
      return false

    fetched = true
    for key, subEntity of @links()
      if eagerness is -1
        if not visited[subEntity.id()]?
          fetched = fetched and subEntity.isFetched(eagerness - 1, visited)
      else
        fetched = fetched and subEntity.isFetched(eagerness - 1, visited)

    # Save eagerness
    if fetched
      visited[@id()] = eagerness

    return fetched


  # Core
  # Fetch entity further given eagerness
  fetch: (opts) ->
    @$.weaver.get(@$.id, opts)


  # Core
  # Pushes key to server
  push: (attribute, value) ->

    # Convenience method for entity.id -> entity
    if isEntity(attribute)

      # Update local
      if not @[attribute.id()]?
        @[attribute.id()] = attribute

      @$.weaver.socket.emit('link', {id: @$.id, key: attribute.id(), target: attribute.id()})

    else

      # Update local
      if not @[attribute]?
        @[attribute] = value


      if isEntity(value)
        @$.weaver.socket.emit('link', {id: @$.id, key: attribute, target: value.id()})
      else
        @$.weaver.socket.emit('update', {id: @$.id, attribute, value: @[attribute]})


  # Core
  # Removes key from server
  remove: (key) ->
    # Convenience method for entity.id -> entity
    if isEntity(key)
      delete @[key.id()]
      @$.weaver.socket.emit('unlink', {id: @$.id, key: key.id()})
    else
      delete @[key]
      @$.weaver.socket.emit('unlink', {id: @$.id, key})


  # Core
  # Removes entity from server and any linked entities
  destroy: ->
    @$.weaver.socket.emit('delete', {id: @$.id})



  weaver: (weaver) ->
    @$.weaver = weaver
    @

  isEntity: ->
    true

  withoutEntities: ->
    delete @[key] for key, val of @links()
    @