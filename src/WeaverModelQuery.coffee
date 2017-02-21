Weaver        = require('./Weaver')
util          = require('./util')
ChirqlManager = require('./ChirqlManager')
Chirql        = require('chirql')

# Converts a string into a regex that matches it.
# Surrounding with \Q .. \E does this, we just need to escape any \E's in
# the text separately.
quote = (s) ->
  '\\Q' + s.replace('\\E', '\\E\\\\E\\Q') + '\\E';


class ModelQuery

  constructor: ->
    @chirqlManager = new ChirqlManager('SPARQL', [{ prefix:'wv:', namespace:'http://weav.er#' }])

  applyModel: (model)->
    @model = model

  getQueryString: ->

    parseQueryFrag = (key,item)=>
      if @model['staticProps']['rels'][key]
        suffix = '(wv:' + @model['staticProps']['rels'][key][0].nodeId + ') '
      else if @model['staticProps']['attrs'][key]
        suffix = '(' + @model['staticProps']['attrs'][key] + ') '
      else
        suffix = ' '
      if item.charAt(0) is '@'
        ' wv:' + item.substring(1) + suffix
      else
        ' <wv:' + item + '>' + suffix
    queryString = ''
    (queryString += parseQueryFrag(key,item)) for key,item of @model['definition']
    '{ ' + queryString + ' }'

  executeQuery: ->
    query = @getQueryString()
    @chirqlManager.query(query).then((res)=>
      ids = (i.root.value for i in res.results.bindings)
      cleanIds = (@chirqlManager.chirql.queryManager.removeNamespaceIfNamespace(id).substring(3) for id in ids)
      promises = (@model.loadMember(id) for id in cleanIds)
      Promise.all(promises).then((res)->
        res
      )
    )

module.exports = ModelQuery
