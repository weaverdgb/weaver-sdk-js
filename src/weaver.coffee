# Libs
io          = require('socket.io-client')
cuid        = require('cuid')
Promise     = require('bluebird')

# Dependencies
Socket      = require('./socket')
Entity      = require('./entity')
Repository  = require('./repository')
WeaverCommons = require('weaver-commons-js')

# Main class exposing all features
module.exports =
class Weaver

  # Expose classes
  @Entity     = Entity
  @Socket     = Socket
  @Repository = Repository

  constructor: ->
    console.log '=^^=|_!!!!!!!!!!!'
    @repository = new Repository(@)

  # Core
  # Create a socket connection to use for getting and adding entities
  connect: (address) ->
    @channel = new Socket(address)
    @

  # Core
  # Disconnect the socket connection
  disconnect: ->
    @channel.disconnect()
    @

  # Core
  # Send authentication info
  authenticate: (token) ->
    @channel.authenticate(token)

  # Core
  # Set a database to use for getting and adding entities
  database: (database) ->
    @channel = database
    @

  endBulk: ->
    @channel.endBulk()

  startBulk: ->
    @channel.startBulk()

  # Core
  # Adds a new entity to Weaver
  # Returns both the entity created and the promise to create it
  _add: (data, type, id) ->
    # console.log '=^^=|_add'
    # console.log data
    # console.log type
    # console.log id
    entity = new Entity(data, type, true, id).$weaver(@)
    
    # console.log '=^^=|_add_the_entity'
    # console.log entity
    # Save to server
    relations  = {}
    attributes = {}

    isEntity = (value) ->
      typeof value.$isEntity is 'function' and value.$isEntity()

    attributes[key] = value for key, value of data when not isEntity(value)
    relations[key]  = value.$id() for key, value of data when isEntity(value)

    createPromise = @channel.create({type, id:entity.$id(), attributes, relations})

    # Save in repository and return
    {
      entity: @repository.store(entity)
      createPromise: createPromise
    }

  # Returns the promise part of the adds functionality
  addPromise: (data, type, id) ->
    @_add(data, type, id).createPromise

  # Returns the entity part of the adds functionality
  add: (data, type, id) ->
    @_add(data, type, id).entity

  # The old weaver.add converted to the new way, It will inserts a entity into db
  node: (object, id) ->
    console.log '=^^=|_'
    console.log object
    console.log id
    # relations = []
    payload = {}
    attributes = []
    for key, value of object
      attribute = {}
      console.log key + ':' + value
      if key is 'id'
        attributes[attributes.length-1].id = value
      else
        attribute.key = key
        attribute.value = value
        attributes.push(attribute)
    console.log attributes
    payload.id = id
    if attributes.length != 0
      payload.attributes = attributes
    
    @channel.create(payload)
    
  dict: (object, id) ->
    

  # Core
  # Creates an Entity of type $COLLECTION
  collection: (id) ->
    @add({}, '$COLLECTION', id)

  # Core
  # Loads an entity either from the local repository or from the server
  get: (id, opts) ->
    console.log '=^^=|_GET'
    # Default options
    opts = {} if not opts?
    opts.eagerness = 1 if not opts.eagerness?
    @channel.read({id, opts}).bind(@).then((object) ->
      try
        entity = Entity.build(object, @)
        # Store entity and sub-entities in the repository and return it
        @repository.store(entity)
      catch error
        # proEnty = JSON.parse(object)
        JSON.parse(object)
        # if proEnty.attributes and proEnty.attributes.length != 0
          # console.log proEnty
          # proEnty
          

      # Store entity and sub-entities in the repository and return it
      # @repository.store(entity)
    )


  getView: (id) ->
    @get(id, -1).then((viewEntity) ->
      new WeaverCommons.model.View(viewEntity)
    )


  # Utility
  # Prints the entity to the console after loading is finished
  print: (id, opts) ->
    @get(id, opts).bind(@).then((entity) ->
      console.log(entity)
    )

  # Utility
  # Returns an entity in the local repository
  local: (id) ->
    @repository.get(id)


# Browser export
window.Weaver = Weaver if window?
