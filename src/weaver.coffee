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

  endBulk: ->
    @channel.endBulk()

  startBulk: ->
    @channel.startBulk()

  # The old weaver.add converted to the new way, It will inserts a entity into db
  node: (object, id) ->
    weaverEntity = new WeaverEntity(object,id)
    @channel.create(weaverEntity).then((object) ->
      if object == 200
        weaverEntity
      else
        'error'
    )
    
  dict: (object, id) ->
    weaverEntity = new WeaverEntity(object, id)
    @channel.createDict(weaverEntity)
    
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
      
  getNode: (id, opts) ->
    # Default options
    opts = {} if not opts?
    opts.eagerness = 1 if not opts.eagerness?
    @channel.read({id, opts}).bind(@).then((object) ->
      try
        JSON.parse(object)
      catch error
        'Error reading ' + id
    )
    
  link: (source, relationTarget) ->
    entity = new WeaverEntity().relate(source,relationTarget)
    console.log '=^^=|_TheEntity_relation_after'
    console.log entity
    @channel.link(entity).then((object) ->
      if object == 200
        entity
      else
        'error'
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

###
weaver.node({isEvil:true,actionZone:'Maryland'},'samantha');
weaver.node({isEvil:true,actionZone:'Tokyo'},'toshio');
weaver.node({isEvil:true,actionZone:'MiddleEarth'},'sauron');

????????????????
weaver.node({isEvil:true,actionZone:'MiddleEarth'}).then((sauron)->

    weaver.link('gandalf',{enemy: sauron});

);

weaver.node({isEvil:false,size:20,name:'Sam'}).then(function(sam){weaver.link(sam,{friend:'gandalf'})})


weaver.node({isEvil:false,actionZone:'MiddleEarth'},'gandalf').then(function(res){weaver.link(res,{isFriend:'father'})})

weaver.link('father',{isFriend:'gandalf'})

weaver.link('samantha',{hasFriend:['toshio','sauron'],hasEnemy:'father'})

weaver.getNode('samantha',{eagerness:3}).then(function(res){console.log(res)})

###


# Browser export
window.Weaver = Weaver if window?
