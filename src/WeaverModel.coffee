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

    # this attribute is used only for db storage purposes
    # - it should not be accessed directly.
    @set('definition', circJSON.stringify(@definition))
    @

  equalTo: (key, val)->

    if util.isArray(@definition[key])# add relation constraint
      @staticProps.rels[key] = [] if not @staticProps.rels[key]?
      @staticProps.rels[key].push(val)

    else # add attribute constraint
      @staticProps.attrs[key] = val
    @

  buildClass: ->

    _def           = @definition
    _statics       = @staticProps

    class WeaverModelInstance extends WeaverNode

      constructor: (@nodeId)->

        @definition = _def
        @staticProps = _statics

        super(@nodeId)
        @relation(@definition[key][0]).add(rel) for rel in val for key,val of @staticProps.rels
        @setProp(key,val) for key,val of @staticProps.attrs

        @

      get: (key)->
        if util.isArray(@definition[key])
          objects = []
          objects.push(obj) for pred,obj of @relations[@definition[key][0]].nodes
          return objects
        @attributes[@definition[key]]

      setProp: (key, val)->

        return Error WeaverError.FILE_NOT_EXISTS_ERROR if not @definition[key]

        if util.isArray(@definition[key])# adds new relation
          @relation(@definition[key][0]).add(val)

        else # adds new attribute
          @set(@definition[key],val)
        @



    return WeaverModelInstance



module.exports = WeaverModel
