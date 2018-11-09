cuid        = require('cuid')
Operation   = require('./Operation')
Weaver      = require('./Weaver')
Promise     = require('bluebird')

class Record

  constructor: (@toNode, @relNode) ->
  equals: (record) ->
    record.relNode.equals(@relNode)

class WeaverRelation

  @Record = Record

  constructor: (@owner, @key) ->
    @_pendingWrites = []                    # All operations that need to get saved
    @_records = []

  _removeRecord: (record) ->
    i = 0
    while i < @_records.length
      rec = @_records[i]
      if rec.equals(record)
        @_records.splice(i, 1)
      else
        i++

  _getRecordsForToNode: (toNode) ->
    (record for record in @_records when record.toNode.equals(toNode))

  getRecords: (node) ->
    @_getRecordsForToNode(node)
      
  load: ->
    new Weaver.Query()
    .restrict(@owner)
    .selectOut(@key, '*')
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
    list = new Weaver.NodeList()
    for record in @_records
      add = true
      add &&= !record.toNode.equals(node) for node in list
      list.push(record.toNode) if add
    list

  allRecords:  ->
    @_records

  first: ->
    @allRecords()[0]?.toNode

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
    @_pendingWrites.push(Operation.Node(@owner).createRelation(@key, node, relId, undefined, false, graph)) if addToPendingWrites
    relationNode

  update: (oldNode, newNode) ->

    oldRecords = undefined
    if oldNode instanceof Record 
      oldRecords = [oldNode]
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

    @_update(oldRecord, newRecord) for oldRecord in oldRecords

  _update: (oldRecord, newRecord) ->

    @_removeRecord(oldRecord)
    @_records.push(newRecord)

    operation = Operation.Node(@owner).createRelation(@key, newRecord.toNode, newRecord.relNode.id(), oldRecord.relNode.id(), Weaver.getInstance()._ignoresOutOfDate, newRecord.relNode.getGraph())
    @_pendingWrites.push(operation)
    Weaver.publish("node.relation.update", {node: @owner, key: @key, oldTarget: oldRecord.toNode, target: newRecord.toNode})
    return

  remove: (node, project) ->
    if node instanceof Record
      @_remove(node, project)
    else 
      Promise.mapSeries(@_getRecordsForToNode(node), (record) =>
        @_remove(record, project)
      )

  _remove: (record, project) ->
    # remove locally
    @_removeRecord(record)
    Weaver.publish("node.relation.remove", {node: @owner, key: @key, target: record.toNode})
    
    # destroy relation
    if !record.relNode._stored
      Promise.resolve()
    else 
      record.relNode.destroy(project)
      
  only: (node, project) ->
    Promise.mapSeries(@_records, (record)=>
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
      Promise.mapSeries(rest, (record) =>
        @_remove(record, project)
      )
    else
      Promise.resolve()

# Export
module.exports  = WeaverRelation
