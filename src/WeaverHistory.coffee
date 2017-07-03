Weaver  = require('./Weaver')



class WeaverHistory

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
    Weaver.getCoreManager().dumpHistory({@limit})

  getHistory: (nodeField, keyField, fromField, toField)->
    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
    typeIsObject = (value) -> typeof value is 'object'
    ids = []
    if nodeField?
      if typeIsArray nodeField
        for node in nodeField
          if typeIsObject node
            ids.push(node.id())
          else
            ids.push(node)
      else
        if typeIsObject nodeField
          ids.push(nodeField.id())
        else
          ids.push(nodeField)
    else
      ids = null
    keys = if typeIsArray keyField then keyField else [keyField] if keyField?
    tos = if typeIsArray toField then toField else [toField] if toField?
    froms = if typeIsArray fromField then fromField else [fromField] if fromField?
    Weaver.getCoreManager().getHistory({ids, keys, froms, tos, @fromDateTime, @beforeDateTime, @users, @limit})


# Export
module.exports = WeaverHistory
