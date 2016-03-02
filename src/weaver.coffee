# Libs
io          = require('socket.io-client')
cuid        = require('cuid')
Promise     = require('bluebird')

# Dependencies
Socket      = require('./socket')
Entity      = require('./entity')
Repository  = require('./repository')

# Main class exposing all features
module.exports =
class Weaver

  constructor: (@address) ->
    @socket     = new Socket(@address)
    @repository = new Repository(@)

  # Core
  # Adds a new entity to Weaver
  add: (data, type, id) ->
    entity = new Entity(data, type, true, id).$weaver(@)

    # Save to server
    @socket.create(type, entity.$id(), data)

    # Save in repository and return
    @repository.store(entity)


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
      @socket.read(id, opts).bind(@).then((object) ->

        # Transform the object into a nested Entity object
        entity = Entity.build(object, @)

        # Store entity and sub-entities in the repository and return it
        @repository.store(entity)
      )


  # Utility
  # Prints the entity to the console after loading is finished
  print: (id, opts) ->
    @get(id, opts).then((entity) ->
      console.log(entity)
    )


  # Utility
  # Returns an entity in the local repository
  local: (id) ->
    @repository.get(id)


# Browser export
window.Weaver = Weaver if window?