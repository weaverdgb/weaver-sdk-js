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

  loadMember: (id)->
    new Promise( (resolve, reject)=>
      MemberClass = @buildClass()
      Weaver.Node.load(id).then((res)->
        member = new MemberClass(res.nodeId)
        member._loadFromQuery(res)
        resolve(member)
      )
    )

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
                promises = []
                for pred,obj of @relations[@definition[key].substr(1)].nodes
#                  console.log(obj)
                  promises.push(model.loadMember(obj.nodeId))

                Promise.all(promises).then((res)->
                  Promise.resolve(res)
                )
              )
            else
              Promise.resolve(obj for pred,obj of @relations[@definition[key].substr(1)].nodes)

          else
            Promise.resolve(@attributes[@definition[key]])

        else # do a recursive 'get' through child models
          path = splitPath.slice(1).join('.')
          if @definition[key].charAt(0) is '@'
            promises = []
            Weaver.Node.load(@subModels[key]).then((node)=>
              model = new Weaver.Model()
              model._loadFromQuery(node)
              promises = []
              for pred,obj of @relations[@definition[key].substr(1)].nodes
                promises.push(model.loadMember(obj.nodeId))

              Promise.all(promises).then((res)->
                promises = (obj.get(path) for obj in res)

                Promise.all(promises).then((arr)->
                  if isFlattened
                    Promise.resolve(util.flatten(arr, isFlattened))
                  else
                    Promise.resolve(arr)
                )
              )
            )


      setProp: (key, val)->

        return Error Weaver.Error.MODEL_PROPERTY_NOT_FOUND if not @definition[key]?

        if @definition[key].charAt(0) is '@' #util.isArray(@definition[key])# adds new relation
          @relation(@definition[key].slice(1)).add(val)

        else # adds new attribute
          @set(@definition[key],val)
        @

    return WeaverModelMember

module.exports = WeaverModel
