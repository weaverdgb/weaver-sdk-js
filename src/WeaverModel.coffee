Weaver      = require('./Weaver')
WeaverNode  = require('./WeaverNode')
WeaverError = require('./WeaverError')
util        = require('./util')
circJSON    = require('circular-json')



class WeaverModel extends WeaverNode

  constructor: (@name, @nodeId)->
    super(@nodeId)
    @set('name', @name) if @name
    @

  structure: (@definition)->

    @staticProps = {rels:{},attrs:{}}

    val[1] = val[1].nodeId if not util.isString(val) for key,val of @definition
    # this attribute is used only for db storage purposes
    # - it should not be accessed directly.
    @set('definition', circJSON.stringify(@definition))
    @

  equalTo: (key, val)->

    if util.isArray(@definition[key])# add static relation for all model instances

#      if @definition[val] # check to see if nested property

      @staticProps.rels[key] = @staticProps.rels[key] or []
      @staticProps.rels[key].push(val)

    else # add attribute static attribute for all model instances
      @staticProps.attrs[key] = val
    @

  buildClass: ->

    _def     = @definition
    _statics = @staticProps

    class WeaverModelMember extends WeaverNode

      constructor: (@nodeId)->
        @definition = _def
        staticProps = _statics
        super(@nodeId)
        @relation(@definition[key][0]).add(rel) for rel in val for key,val of staticProps.rels
        @setProp(key,val) for key,val of staticProps.attrs
        @

      get: (path)->

        splitPath = path.split('.')
        key = splitPath[0]

        if splitPath.length is 1
          # if @definition[key] is an array, they're relations, otherwise they're attributes
          return (obj for pred,obj of @relations[@definition[key][0]].nodes) if util.isArray(@definition[key])
          return @attributes[@definition[key]]

        else # do a recursive 'get' through child models
          path = splitPath.slice(1).join('.')
          arr =  (obj.get(path) for pred,obj of @relations[@definition[key][0]].nodes) if util.isArray(@definition[key])
          util.flatten(arr)# if util.isArray(arr)


      setProp: (key, val)->
        return Error WeaverError.FILE_NOT_EXISTS_ERROR if not @definition[key]

        if util.isArray(@definition[key])# adds new relation
          @relation(@definition[key][0]).add(val)

        else # adds new attribute
          @set(@definition[key],val)
        @

    return WeaverModelMember

module.exports = WeaverModel
