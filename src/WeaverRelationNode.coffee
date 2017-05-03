cuid        = require('cuid')
Operation   = require('./Operation')
WeaverNode  = require('./WeaverNode')

class WeaverRelationNode extends WeaverNode

  getClass: ->
    WeaverRelationNode
  @getClass: ->
    WeaverRelationNode

  constructor: (@nodeId) ->
    throw new Error("Please always supply a relId when constructing WeaverRelationNode") if not @nodeId?
    @_stored = false       # if true, available in database, local node can hold unsaved changes
    @_loaded = false       # if true, all information from the database was localised on construction

    # Store all attributes and relations in these objects
    @attributes = {}
    @relations  = {}

    @toNode = null        # Wip, this is fairly impossible to query this from the server currently
    @fromNode = null      # Wip, this is fairly impossible to query this from the server currently


  to: ->
    @toNode

  from: ->
    @fromNode

  # override
  destroy: (project) ->
    @getWeaver().getCoreManager().executeOperations([Operation.Node(@).destroy()], project).then(=>
      delete @[key] for key of @
      undefined
    )




# Export
module.exports = WeaverRelationNode
