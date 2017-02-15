Weaver      = require('./Weaver')
util        = require('./util')
circJSON    = require('circular-json')



class WeaverModel extends Weaver.Node

  constructor: (@nodeId)->
    super(@nodeId)
    @staticProps = {rels:{},attrs:{}}
    @subModels = {}
    @definition = {}

  structure: (structure)->

    for key,val of structure
      if util.isArray(val)
        @subModels[key] = val[1]
        @definition[key] = val[0]
      else @definition[key] = val

    # this attribute is used only for db storage purposes
    # - it should not be accessed directly.
    @set('definition', circJSON.stringify(@definition))
    @set('subModels', circJSON.stringify(@subModels))
    @

  setStatic: (key, val)->

    throw new Error(Weaver.Error.CANNOT_SET_DEEP_STATIC) if util.isArray(@definition[key])

    if @definition[key].charAt(0) is '@'# add static relation for all model instances
      key = @definition[key].substr(1)
      @staticProps.rels[key] = @staticProps.rels[key] or []
      @staticProps.rels[key].push(val)

    else # add attribute static attribute for all model instances
      @staticProps.attrs[key] = val

    @set('staticProps', circJSON.stringify(@staticProps))
    @

  _loadFromQuery: (object)->
    super(object)
    @definition  = JSON.parse(@attributes.definition)
    @staticProps = JSON.parse(@attributes.staticProps)
    @subModels = JSON.parse(@attributes.subModels)
    @structure(@definition)

  buildClass: ->

    _def     = @definition
    _statics = @staticProps
    _subs    = @subModels

    class WeaverModelMember extends Weaver.Node

      constructor: (@nodeId)->
        @definition = _def
        @subModels  = _subs
        staticProps = _statics
        super(@nodeId)

        for key,val of staticProps.rels
          for rel in val
#            console.log(rel)
            @relation(key).add(new Weaver.Node(rel.nodeId))

        @setProp(key,val) for key,val of staticProps.attrs

      get: (path, isFlattened = true)->

        # isFlattened:  default response should be flat array,
        #               mark this false if property paths are required to be included in response
        splitPath = path.split('.')
        key = splitPath[0]

        if splitPath.length is 1
          if @definition[key].charAt(0) is '@'
            if @subModels[key]
              Weaver.Node.load(@subModels[key]).then((node)=>
                model = new Weaver.Model()
                model._loadFromQuery(node)
                MemberClass = model.buildClass()
                returns = []
                promises = []
                for pred,obj of @relations[@definition[key].substr(1)].nodes
                  member = new MemberClass(obj.nodeId)
                  promises.push(Weaver.Node.load(obj.nodeId).then((res)->
                    member._loadFromQuery(res)
                    returns.push(member)
                  ))
                Promise.all(promises).then(->
                  Promise.resolve(returns)
                )
              )
            else
              Promise.resolve(obj for pred,obj of @relations[@definition[key].substr(1)].nodes)

          else
            Promise.resolve(@attributes[@definition[key]])

        else # do a recursive 'get' through child models
          path = splitPath.slice(1).join('.')
          promises = (obj.get(path) for pred,obj of @relations[@definition[key].substr(1)].nodes) if @definition[key].charAt(0) is '@'
          console.log(promises)
          Promise.all(promises).then((results)->
            console.log(path)
            console.log(results)
            if isFlattened
              Promise.resolve(util.flatten(results, isFlattened))
            else
              Promise.resolve(results)
          )

      setProp: (key, val)->

        return Error Weaver.Error.MODEL_PROPERTY_NOT_FOUND if not @definition[key]?

        if @definition[key].charAt(0) is '@' #util.isArray(@definition[key])# adds new relation
          @relation(@definition[key].slice(1)).add(val)

        else # adds new attribute
          @set(@definition[key],val)
        @

    return WeaverModelMember

  getMember: (node)->
    0

module.exports = WeaverModel
