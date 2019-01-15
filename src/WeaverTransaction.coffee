Promise     = require('bluebird')
cuid        = require('cuid')
Weaver      = require('./Weaver')

class WeaverTransaction

  constructor: ->
    @_id = cuid()

  id: ->
    @_id

  setTtl: (ttl) ->
    @_ttl = ttl

  begin: ->
    Weaver.getCoreManager().begin(@_id, @_ttl)

  rollback: ->
    Weaver.getCoreManager().rollback(@_id)

  commit: ->
    Weaver.getCoreManager().commit(@_id)

  keepAlive: (ttl) ->
    Weaver.getCoreManager().keepAlive(@_id, ttl)
    
# Export
module.exports = WeaverTransaction
