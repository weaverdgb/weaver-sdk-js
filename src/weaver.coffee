# Libs
io            = require('socket.io-client')
# cuid          = require('cuid')
Promise       = require('bluebird')

# Dependencies
Socket        = require('./socket')
Entity        = require('./entity')
WeaverEntity  = require('./weaverEntity')
Repository    = require('./repository')
WeaverCommons = require('weaver-commons-js')
pjson         = require('../package.json')

# Main class exposing all features
module.exports =
class Weaver

  # Expose classes
  @Entity     = Entity
  @Socket     = Socket
  @Repository = Repository

  constructor: ->
    console.log 'WeaverSDK: ' + pjson.version
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

  ###
   Tells the server that the bulk insertion has finished
   Used after startBulk
  ###
  endBulk: ->
    @channel.endBulk()


  ###
   Tells the server that the bulk insertion starts
   Used before endBulk
  ###
  startBulk: ->
    @channel.startBulk()
    
  bulkNodes: (bulkPayload)  ->
    @channel.bulkNodes(bulkPayload).then((object) ->
      if object[0] is '200'
        object[0]
      else
        'error destroying entity'
    )
      
  bulkRelations: (bulkPayload)  ->
    @channel.bulkRelations(bulkPayload).then((object) ->
      if object[0] is '200'
        object[0]
      else
        'error destroying entity'
    )

  ###
   Will inserts a entity into db
   The old weaver.add converted to the new way
  ###
  node: (object, id) ->
    weaverEntity = new WeaverEntity(object,id)
    @channel.create(weaverEntity).then((object) ->
      if object == 200
        weaverEntity
      else
        'error'
    )
    
  ###
   Will update the attributes of an entity
  ###
  update: (object,id) ->
    weaverEntity = new WeaverEntity(object, id)
    @channel.update(weaverEntity).then((res, err) =>
      # console.log '=^^=|_Update'
      # console.log res
      if res[0] == 200
        weaverEntity
      else
        'error'
    )
      
  ###
   Stores data in object format into the Redis db
  ###
  dict: (object, id) ->
    weaverEntity = new WeaverEntity(object, id)
    @channel.createDict(weaverEntity)
  
  ###
   Retireves data from the Redis db
  ###
  getDict: (id) ->
    try
      @channel.readDict({id}).bind(@).then((res, err) =>
        if err
          err
        if res
          res
      )
    catch error
      error
      
      
  ###
   Retireves an entity
  ###
  getNode: (id, opts) ->
    # Default options
    opts = {} if not opts?
    opts.eagerness = 1 if not opts.eagerness?
    if typeof id is 'string'
      id = id
    if typeof id is 'object'
      id = id.id
    @channel.read({id, opts}).bind(@).then((object) ->
      try
        entity = JSON.parse(object)
        if not entity.id and entity.attributes.length is 0 and entity.relations.length is 0
          'The entity does not exits'
        else
          entity
      catch error
        'Error reading ' + id
    )
    
  ###
   Makes a relationship between tow entities
   If any of those does not extits will be created
  ###
  link: (source, relationTarget) ->
    entity = new WeaverEntity().relate(source,relationTarget)
    @channel.link(entity).then((object) ->
      if object == 200
        entity
      else
        'error linking ' + source
    )
    
  ###
   Deletes relationships
  ###
  unlink: (source, relationTarget) ->
    entity = new WeaverEntity().relate(source,relationTarget)
    @channel.unlink(entity).then((object) ->
      if object[0] == '200'
        object[0]
      else
        'error unlinking ' + source
    )
      
  ###
   Wipes the DB
  ###
  wipe: ->
    @channel.wipe().then((object) ->
      if object[0] is '200'
        object[0]
      else
        'error wipping db'
    )
    
    
  ###
   Wipes the weaver DB, (in case of neo4j will removes all the nodes with label:INDIVIDUAL and $ID value property)
  ###
    
  wipeWeaver: ->
    @channel.wipeWeaver().then((object) ->
      if object[0] is '200'
        object[0]
      else
        'error wipping weaver db'
    )
    
  ###
   Deletes an entity (a node)
  ###
    
  destroy: (individual) ->
    entity = new WeaverEntity({},individual)
    @channel.destroy(entity).then((object) ->
      if object[0] is '200'
        object[0]
      else
        'error destroying entity'
    )
    
      

  # getView: (id) ->
  #   @get(id, -1).then((viewEntity) ->
  #     new WeaverCommons.model.View(viewEntity)
  #   )


  # Utility
  # Prints the entity to the console after loading is finished
  # print: (id, opts) ->
  #   @get(id, opts).bind(@).then((entity) ->
  #     console.log(entity)
  #   )

  # Utility
  # Returns an entity in the local repository
  # local: (id) ->
  #   @repository.get(id)


# Browser export
window.Weaver = Weaver if window?
