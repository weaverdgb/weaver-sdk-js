WeaverRoot  = require('./WeaverRoot')



class WeaverHistory extends WeaverRoot

  getClass: ->
    WeaverHistory
  @getClass: ->
    WeaverHistory

  constructor: () ->

  forUser: (userId)->
    @users = [userId]
  forUsers: (userIds)->
    @users = userIds

  fromDateTime: (pattern)->
    @fromDateTime = pattern

  beforeDateTime: (pattern)->
    @beforeDateTime = pattern

  limit: (value) ->
    @limit = value

  dumpHistory: () ->
    @getWeaver().getCoreManager().dumpHistory({@limit})

  getHistory: (nodeField, keyField, toField)->
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
    ids = if typeIsArray nodeField then (node.id() for node in nodeField) else [nodeField.id()]
    keys = if typeIsArray keyField then keyField else [keyField] if keyField?
    tos = if typeIsArray toField then toField else [toField] if toField?
    @getWeaver().getCoreManager().getHistory({ids, keys, tos, @fromDateTime, @beforeDateTime, @users, @limit})

# Export
module.exports = WeaverHistory
