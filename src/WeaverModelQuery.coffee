Weaver        = require('./Weaver')
util          = require('./util')
ChirqlManager = require('./ChirqlManager')
Chirql        = require('chirql')

class ModelQuery

  constructor: ->
    @chirqlManager = new ChirqlManager('SPARQL', [{ prefix:'wv:', namespace:'http://weav.er#' }])

  applyModel: (model)->
    @model = model

  getQueryString: ->

    parseSimpleFragment = (key, item)=>
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

    parseQueryFrag = (key,item)=>
      if item.indexOf('.') isnt -1
        path =  item.split('.')
        nestedModelId = @model.subModels[path[0]]
        newPath = path.slice(-1).join('.')
        Weaver.Node.load(nestedModelId).then((node)=>
          nestedModel = new Weaver.Model(node.id())
          nestedModel._loadFromQuery(node)
          parseQueryFrag(newPath,nestedModel['definition'][newPath])

        ).then((innerFragment)=>
          'wv:' + @model.definition[path[0]].substring(1) + ' { ' + innerFragment + '}'
        )
#        @model.definition[path[0]] + '{ ' + parseQueryFrag(newPath,@model['definition'][newPath]) + '}'
      else
        Promise.resolve(parseSimpleFragment(key,item))

    queryString = ''
    proms = []
    proms.push(parseQueryFrag(key,item)) for key,item of @model['definition']
    Promise.all(proms).then((res)->
      queryString += prom for prom in res
      Promise.resolve('{ ' + queryString + ' }')
    )

  executeQuery: ->
    @getQueryString().then((query)=>
      @chirqlManager.query(query)
    ).then((res)=>
      ids = (i.root.value for i in res.results.bindings)
      halfCleanIds = (@chirqlManager.chirql.queryManager.removeNamespaceIfNamespace(id).substring(3) for id in ids)
      cleanIds = []
      for id in halfCleanIds
        cleanIds.push(id) if cleanIds.indexOf(id) is -1
      promises = (@model.loadMember(id) for id in cleanIds)
      Promise.all(promises)
    )

module.exports = ModelQuery
