cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
Promise     = require('bluebird')

class Record

  constructor: (@toNode, @relNode) ->
  equals: (record) ->
    record.relNode.equals(@relNode)

class WeaverRelation

  constructor: (@owner, @key) ->
    @pendingWrites = []                    # All operations that need to get saved
    @_records = []

  _removeRecord: (record) ->
    i = 0
    while i < @_records.length
      node = @_records[i].relNode
      if node.equals(relNode)
        @_records.splice(i, 1)
      else
        i++

  _getRecordsForToNode: (toNode) ->
    (record.relNode for record in @_records when record.toNode.equals(toNode))
      
  load: () ->
    new Weaver.Query()
    .restrict(@owner)
    .selectOut(@key)
    .selectRelations(@key)
    .find()
    .then((nodes)=>
      reloadedRelation = nodes[0].relation(@key)
      @_records = reloadedRelation.allRecords()
      reloadedRelation.all()
    )

  query: ->
    Promise.resolve([])

  to: (node) ->
    relNode = @_getRecordsForToNode(node)[0]?.relNode
    throw new Error("No relation to a node with this id: #{node.id()}") if not relNode?
    Weaver.RelationNode.load(relNode.id(), null, Weaver.RelationNode, true, false, relNode.getGraph())

  all: ->
    map = {}
    map[record.toNode.id()] = record.toNode for record in @_records
    (node for id, node of map)

  allRecords:  ->
    @_records

  first: ->
    @.allRecords()[0]?.toNode

  addInGraph: (node, graph) ->
    @add(node, undefined, true, graph)

  _createRelationNode: (relId, targetNode, graph) ->
    result = Weaver.RelationNode.get(relId, Weaver.RelationNode, graph)
    result.fromNode = @owner
    result.toNode = targetNode
    result

  add: (node, relId, addToPendingWrites = true, graph) ->
    relId ?= cuid()
    graph ?= @owner.getGraph()
    relationNode = @_createRelationNode(relId, node, graph)
    @_records.push(new Record(node, relationNode))

    Weaver.publish("node.relation.add", {node: @owner, key: @key, target: node})
    @pendingWrites.push(Operation.Node(@owner).createRelation(@key, node, relId, undefined, false, graph)) if addToPendingWrites
    relationNode

  update: (oldNode, newNode) ->

    oldRecords = []
    if oldNode instanceof Record 
      oldRecords.push(oldNode)
    else
      oldRecords = @_getRecordsForToNode(oldNode)

    newRecord = undefined
    if newNode instanceof Record 
      newRecord = newNode 
    else
      newRelId = cuid()
      graph = oldRecords[0]?.relNode.getGraph()
      graph ?= @owner.getGraph()
      newRelNode = @_createRelationNode(newRelId, newNode, graph)
      newRecord = new Record(newNode, newRelNode)

    oldRecord = undefined
    if oldNode instanceof Record 
      oldRecord = oldNode 
      @_update(oldRecord, newRecord)
    else
      Promise.map(@_getRecordsForToNode(oldNode), (oldRecord) =>
        @_update(oldRecord, newRecord)
      )

  _update: (oldRecord, newRecord) ->

    @_removeRecord(oldRecord)
    @_records.push(newRecord)

    operation = Operation.Node(@owner).createRelation(@key, newRecord.toNode, newRecord.relNode.id(), oldRecord.relNode.id(), Weaver.getInstance()._ignoresOutOfDate, newRecord.relNode.getGraph())
    @pendingWrites.push(operation)
    Weaver.publish("node.relation.update", {node: @owner, key: @key, oldTarget: oldNode, target: newNode})

  remove: (node, project) ->
    if node instanceof Record
      @_remove(node, project)
    else 
      Promise.map(@_getRecordsForToNode(node), (record) =>
        @_remove(record, project)
      )

  _remove: (record, project) ->
    # remove from list
    @_removeRecord(record)
    
    # destroy relation node
    # TODO: This failed when relation is not saved, should be able to only remove locally: CREATE TEST
    Promise.resolve()
    .then(
      if record.relNode._stored 
        record.relNode.destroy(project)
      else 
        Promise.resolve()
    ).then(=>
      Weaver.publish("node.relation.remove", {node: @owner, key: @key, target: node})
    )
    
  only: (node, project) ->
    Promise.map(@_records, (record)=>
      @_remove(record, project) if !record.toNode.equals(node)
    ).then(=>
      @add(node) if @_records.length is 0
      @owner.save(project)
    )
    
  onlyOnce: (node, project) ->
    [first, rest...] = @_getRecordsForToNode(node)
    if !first?
      @add(node) 
      @owner.save(project)
    else if rest.length > 0
      Promise.map(rest, (record) =>
        @_remove(record, project)
      )
    else
      Promise.resolve()

# Export
module.exports  = WeaverRelation
