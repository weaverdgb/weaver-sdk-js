Weaver      = require('./Weaver')
util        = require('./util')
circJSON    = require('circular-json')



class WeaverModel extends Weaver.Node

  constructor: (@name, @nodeId)->
    super(@nodeId)
    @set('name', @name) if @name
    @

  structure: (@definition)->

    @staticProps = {rels:{},attrs:{}}

    # this attribute is used only for db storage purposes
    # - it should not be accessed directly.
    @set('definition', circJSON.stringify(@definition))
    @

  setStatic: (key, val)->

    throw new Error(Weaver.Error.CANNOT_SET_DEEP_STATIC) if util.isArray(@definition[key])

    if @definition[key].charAt(0) is '@' # util.isArray(@definition[key])# add static relation for all model instances

      key = @definition[key].substr(1)
      @staticProps.rels[key] = @staticProps.rels[key] or []
      @staticProps.rels[key].push(val)

    else # add attribute static attribute for all model instances
      @staticProps.attrs[key] = val
    @

  buildClass: ->

    _def     = @definition
    _statics = @staticProps

    class WeaverModelMember extends Weaver.Node

      constructor: (@nodeId)->
        @definition = _def
        staticProps = _statics
        super(@nodeId)
        @relation(key).add(rel) for rel in val for key,val of staticProps.rels

        @setProp(key,val) for key,val of staticProps.attrs
        @

      get: (path, isFlattened = true)->
        return @get(@definition[path].join('.')) if util.isArray(@definition[path])

        # isFlattened:  default response should be flat array,
        #               mark this false if property paths are required to be included in response

        splitPath = path.split('.')
        key = splitPath[0]

        if splitPath.length is 1
          # if @definition[key] is an array, they're relations, otherwise they're attributes
          return (obj for pred,obj of @relations[@definition[key].substr(1)].nodes) if @definition[key].charAt(0) is '@'
          return @attributes[@definition[key]]

        else # do a recursive 'get' through child models
          path = splitPath.slice(1).join('.')
          arr =  (obj.get(path) for pred,obj of @relations[@definition[key].substr(1)].nodes) if @definition[key].charAt(0) is '@'
          if isFlattened
            util.flatten(arr, isFlattened)
          else
            arr

      setProp: (key, val)->

        return Error Weaver.Error.FILE_NOT_EXISTS_ERROR if not @definition[key]

        if @definition[key].charAt(0) is '@' #util.isArray(@definition[key])# adds new relation
          @relation(@definition[key].slice(1)).add(val)

        else # adds new attribute
          @set(@definition[key],val)
        @

    return WeaverModelMember

module.exports = WeaverModel
