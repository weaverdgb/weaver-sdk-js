Weaver        = require('./Weaver')
util          = require('./util')
ChirqlManager = require('./ChirqlManager')
Chirql        = require('chirql')

class ModelQuery

  constructor: ->
    @chirqlManager = new ChirqlManager('SPARQL', [{ prefix:'wv:', namespace:'http://weav.er#' }]) #instantiate a chirqlManager with one default namespace

  applyModel: (model)->
    @model = model

  getQueryString: ->

    pref = 'wv:' # default prefix

    parseSimpleFragment = (key, item)=>
      if @model['staticProps']['rels'][key]
        suffix = '(' + pref + @model['staticProps']['rels'][key][0].nodeId + ') '
      else if @model['staticProps']['attrs'][key]
        suffix = '(' + @model['staticProps']['attrs'][key] + ') '
      else
        suffix = ' '
      if item.charAt(0) is '@'
        ' ' + pref + item.substring(1) + suffix
      else
        ' <' + pref + item + '>' + suffix

    parseQueryFrag = (key,item,modelRef)=>
      model = modelRef or @model
      console.log(key)
      console.log(item)

      if item.indexOf('.') is -1
        Promise.resolve(parseSimpleFragment(key,item))

      else # some nesting is required
        path =  item.split('.')
        nestedModelId = model.subModels[path[0]]
        newPath = path.slice(1).join('.')
        Weaver.Node.load(nestedModelId).then((node)=> # load submodel structure
          nestedModel = new Weaver.Model(node.id())
          nestedModel._loadFromQuery(node)
          parseQueryFrag(newPath,nestedModel['definition'][newPath],nestedModel)

        ).then((innerFragment)=>
          pref + model.definition[path[0]].substring(1) + ' { ' + innerFragment + '} '
        )

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
