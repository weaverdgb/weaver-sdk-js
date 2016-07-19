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
  # Set a database to use for getting and adding entities
  database: (database) ->
    @channel = database
    @

  # Core
  # Adds a new entity to Weaver
  # Returns both the entity created and the promise to create it
  _add: (data, type, id) ->
    entity = new Entity(data, type, true, id).$weaver(@)

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

  # Core
  # Creates an Entity of type $COLLECTION
  collection: (id) ->
    @add({}, '$COLLECTION', id)

  # Core
  # Loads an entity either from the local repository or from the server
  get: (id, opts) ->
    # Default options
    opts = {} if not opts?
    opts.eagerness = 1 if not opts.eagerness?

    if @repository.contains(id) and @repository.get(id).$isFetched(opts.eagerness)
      Promise.resolve(@repository.get(id))
    else
      # Server read
      @channel.read({id, opts}).bind(@).then((object) ->

        # Transform the object into a nested Entity object
        entity = Entity.build(object, @)

        # Store entity and sub-entities in the repository and return it
        @repository.store(entity)
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
