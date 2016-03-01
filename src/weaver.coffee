# Libs
io          = require('socket.io-client')
cuid        = require('cuid')
Promise     = require('bluebird')

# Dependencies
Socket      = require('./socket')
Entity      = require('./entity')
Repository  = require('./repository')

module.exports =
class Weaver
  
  constructor: (@address) ->
    @socket     = new Socket(@address)
    @repository = new Repository(@)
    
  entity: (data, type) ->
    entity = new Entity(data, type).weaver(@)
    
    # Save to server
    @socket.create(type, entity.id(), data)

    # Save in repository and return
    @repository.store(entity)
    
  
  # Prints entity after loading
  print: (id, opts) ->
    @load(id, opts).then((entity) ->
      console.log(entity)
    )

    
  # Returns an entity in the local repository
  local: (id) ->
    @repository.get(id)

    
  # Loads entity either from local repository or from server
  load: (id, opts) ->    
    # Default options
    opts = {} if not opts?
    opts.eagerness = 1 if not opts.eagerness?
    
    if @repository.contains(id) and @repository.get(id).isFetched(opts.eagerness)
      Promise.resolve(@repository.get(id))
    else
      # Server read
      @socket.read(id, opts).bind(@).then((object) ->

        # Transform the object into a nested Entity object
        entity = Entity.build(object, @)
        
        # Store entity and sub-entities in store
        storedEntity = @repository.store(entity)
        
        return storedEntity
      )

# Browser export
window.Weaver = Weaver if window?