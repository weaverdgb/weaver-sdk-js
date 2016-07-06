# Libs
cuid = require('cuid')

# Helper functions
isObject = (object) ->
  Object.prototype.toString.call(object) is '[object Object]'

isReference = (object) ->
  object['_REF']?

isEntity = (value) ->
  typeof value.$isEntity is 'function' and value.$isEntity()

# Entity class exposing entity features
module.exports =
class Entity

  # Creates an Entity object from a native server object
  @create: (object) ->
    # Metadata
    type    = object['_META'].type
    fetched = object['_META'].fetched
    id      = object['_META'].id
    data    = object['_ATTRIBUTES']

    # Init if not set
    data = {} if not data?

    # Copy Relations
    data[key] = value for key, value of object['_RELATIONS'] if object['_RELATIONS']?

    new Entity(data, type, fetched, id)


  # Builds a deeply nested Entity object from a native server object
  @build: (object, weaver) ->
    references = {}

    # Create references
    register = (value) ->
      entity = Entity.create(value).$weaver(weaver)
      references[entity.$id()] = entity

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
    type = '$ROOT' if not type?

    # Locally created is always fetched
    fetched = true if not fetched?

    # Store any non-content of this entity under the $ variable
    @$ = {id, type, fetched, listeners: {}}

    # Copy keys from data
    @[key] = value for key, value of data



  # Core
  # Get ID
  $id: ->
    @$.id


  # Core
  # Get type
  $type: ->
    @$.type


  # Core
  # Get all values that are not entities
  $values: ->
    values = {}
    values[key] = value for own key, value of @ when key isnt '$' and key isnt isEntity(value)
    values


  # Core
  # Get all entities
  $links: ->
    links = {}
    links[key] = value for own key, value of @ when isEntity(value)
    links


  # Core
  # Get all entities in an array
  $linksArray: ->
    (value for own key, value of @ when isEntity(value))


  # Core
  # Test whether this entity is fetched given the eagerness
  $isFetched: (eagerness, visited) ->
    # Default
    eagerness = 1 if not eagerness?

    # Start with an empty map of visited entities
    visited = {} if not visited?

    # Early return because of visited before
    if visited[@$id()]? and eagerness > -1 and visited[@$id()] >= eagerness
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

    # Save eagerness
    visited[@$id()] = eagerness

    fetched = true
    for key, subEntity of @$links()
      if eagerness is -1
        if not visited[subEntity.$id()]?
          fetched = fetched and subEntity.$isFetched(eagerness, visited)
      else
        fetched = fetched and subEntity.$isFetched(eagerness - 1, visited)

    return fetched


  # Core
  # Fetch entity further given eagerness
  $fetch: (opts) ->
    @$.weaver.get(@$.id, opts)


  # Core
  # Pushes key to server
  $push: (attribute, value) ->

    # Convenience method for entity.id -> entity
    if isEntity(attribute)

      # Update local
      if not @[attribute.$id()]?
        @[attribute.$id()] = attribute

      if @$.weaver.channel?
        payload =
          source:
            id: @.$id()
            type: @.$type()
          key: attribute.$id()
          target:
            id: attribute.$id()
            type: attribute.$type()

        @$.weaver.channel.link(payload)

    else

      # Update local
      if value?
        @[attribute] = value if @[attribute] isnt value
      else
        value = @[attribute]

      if @$.weaver.channel?
        if isEntity(value)
          payload =
            source:
              id: @.$id()
              type: @.$type()
            key: attribute
            target:
              id: value.$id()
              type: value.$type()

          @$.weaver.channel.link(payload)
        else
          payload =
            source:
              id: @.$id()
              type: @.$type()
            key: attribute
            target:
              value: value
              datatype: ''

          @$.weaver.channel.update(payload)


  # Core
  # Removes key from server
  $remove: (key) ->
    # Convenience method for entity.id -> entity
    if isEntity(key)
      delete @[key.$id()]

      if @$.weaver.channel?
        @$.weaver.channel.unlink({id: @$.id, key: key.$id()})
    else

      value = @[key]
      delete @[key]

      if @$.weaver.channel?
        if isEntity(value)
          @$.weaver.channel.unlink({id: @$.id, key: key})
        else
          @$.weaver.channel.remove({id: @$.id, attribute: key})


  # Core
  # Removes entity from server and any linked entities
  $destroy: ->
    if @$.weaver.channel?
      @$.weaver.channel.destroy({id: @$.id})

  # Core
  # Triggers when any change happens
  $on: (key, callback) ->
    if not @$.listeners[key]?
      @$.listeners[key] = []

    @$.listeners[key].push(callback)


  $fire: (key) ->
    if @$.listeners[key]?
      for callback in @$.listeners[key]
        callback.call(key)


  $weaver: (weaver) ->
    @$.weaver = weaver
    @

  $isEntity: ->
    true

  $withoutEntities: ->
    delete @[key] for key, val of @$links()
    @
