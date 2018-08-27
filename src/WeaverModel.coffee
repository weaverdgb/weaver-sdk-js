cuid                 = require('cuid')
Promise              = require('bluebird')
Weaver               = require('./Weaver')
ModelContext         = require('./WeaverModelContext')
ModelValidator       = require('./WeaverModelValidator')
WeaverError          = require('./Error')
_                    = require('lodash')

class WeaverModel extends ModelContext

  constructor: (definition) ->
    super(definition)

  init: ->

    # Map classId to ModelClass
    @classList = {} 

    # Maps 'model-name@version' to the context object
    @contextMap = {}
    @contextMap["#{@definition.name}@#{@definition.version}"] = @
    @loadMap = {}
    @loadMap[@definition.name] = @definition.version
    
    # Deprecated
    @modelMap = {}  
    @modelMap[@definition.name] = @
    @includes = {}
    
    @_loadIncludes(@definition)
    .then(=> 
      # # todo: validate everything
      # new ModelValidator(@definition).validate() 

      # Bring model to life
      for modelTag, context of @contextMap
        for prefix, incl of context.definition.modelPrefixes
          context[prefix] = @contextMap[incl.tag]

      for modelTag, context of @contextMap
        for className, classDefinition of context.definition.classes
          if context.isNativeClass(className)
            @_registerClass(context, className, classDefinition) 

      for modelTag, context of @contextMap
        for className, classDefinition of context.definition.classes
          if context.isNativeClass(className)
            context[className].totalClassDefinition = @_collectFromSupers(classDefinition, context)

      for modelTag, context of @contextMap
        for className, classDefinition of context.definition.classes
          if context.isNativeClass(className)
            context[className].totalRangesMap = @_buildRanges(context[className].totalClassDefinition, context) 
          
      @
    )

  _registerClass: (context, className, classDefinition)->

    js = new Function('Weaver', """
      return class #{className} extends Weaver.ModelClass {
        constructor(nodeId, graph) {
          super(nodeId, graph, #{className}.model);

          // Reflect class fields inward to instance
          this.className            = "#{className}";
          this.model                = #{className}.model;
          this.context              = #{className}.context;
          this.definition           = #{className}.definition;
          this.classDefinition      = #{className}.classDefinition;
          this.totalClassDefinition = #{className}.totalClassDefinition;
          this.totalRangesMap       = #{className}.totalRangesMap;
        }
      }""")

    modelClass = js(Weaver)
    modelClass.className            = className
    modelClass.model                = @
    modelClass.context              = context
    modelClass.definition           = @.definition
    modelClass.classDefinition      = classDefinition
    modelClass.classId              = -> @.context.getNodeNameByKey(@.className)

    # Also undefind is a valid as agrument for graph
    load = (loadClass) => (nodeId, graph) =>
      query = new Weaver.ModelQuery(@)
      .class(context[loadClass])
      .restrict(nodeId)
      query.restrictGraphs([graph]) if arguments.length > 1
      query.first(context[loadClass])

    modelClass.load = load(className)
    modelClass.loadFromGraph = load(className)

    context[className] = modelClass
    @classList[modelClass.classId()] = modelClass

  # Recurs over all definitions filling the contextMap
  _loadIncludes: (definition) ->
    return Promise.resolve() if not definition.includes?

    # Add map with local prefix to contextMap key
    definition.modelPrefixes = {}
    definition.modelPrefixes[key] = {prefix: key, name: obj.name, version: obj.version, tag: "#{obj.name}@#{obj.version}"} for key, obj of definition.includes

    # Depth first to prevent concurrent version checks
    Promise.mapSeries((inc for key, inc of definition.modelPrefixes), (obj)=>

      if @loadMap[obj.name]?
        if @loadMap[obj.name] isnt obj.version
          error = new WeaverError(209, "Model #{@definition.name} tries to include #{obj.name} but this introduces a cycle")
          return Promise.reject(error) 
        else
          # Definition is already loaded
          return Promise.resolve()
      
      @loadMap[obj.name] = obj.version
      @modelMap[obj.name] = @ # Deprecated, set for backbward compatibility

      WeaverModel._loadDefinition(obj.name, obj.version)
      .then((includedModel)=>
        context = new ModelContext(includedModel.definition, @)
        @contextMap[obj.tag] = context
        @includes[obj.prefix] = context  # Deprecated, set for backbward compatibility
        @_loadIncludes(includedModel.definition)
      )
    )

  _collectFromSupers: (classDefinition, context)->
    addFromSuper = (cd, context, definition = @definition, totalDefinition = {attributes: {}, relations: {}}) =>

      # Start with supers so lower specifications override the super ones
      if cd?.super?
        superClassId = context.getNodeNameByKey(cd.super)
        superDefinition = @classList[superClassId].classDefinition
        addFromSuper(superDefinition, @classList[superClassId].context, definition, totalDefinition)

      transfer = (source) =>
        for k, v of cd?[source]
          if cd?[source]?
            totalDefinition[source][k] = v
            if v?.range?
              updatedRanges = []
              ranges = v.range
              ranges = _.keys(ranges) if not _.isArray(ranges)
              for range in ranges
                updated = context.getNodeNameByKey(range)
                updatedRanges.push(updated)
              totalDefinition[source][k].range = updatedRanges

      transfer('attributes')
      transfer('relations')

      totalDefinition

    addFromSuper(classDefinition, context)


  _buildRanges: (totalClassDefinition, context) ->
    map = {}
    map[key] = @_getRanges(key, totalClassDefinition, context) for key, obj of totalClassDefinition.relations
    map

  _getRanges: (key, totalClassDefinition, context)->

    addSubRange = (range, ranges = []) =>

      for modelTag, context of @contextMap
        for className, definition of context.definition.classes
          if definition?.super?
            superClassId = context.getNodeNameByKey(definition.super)
            if superClassId is range
              ranges.push(context.getNodeNameByKey(className))
              # Follow again for this subclass
              addSubRange(context.getNodeNameByKey(className), ranges)

      ranges

    totalRanges = []
    for rangeKey in @_getRangeKeys(key, totalClassDefinition)
      totalRanges.push(rangeKey)
      totalRanges = totalRanges.concat(addSubRange(rangeKey))

    totalRanges

  _getRangeKeys: (key, totalClassDefinition)->
    return [] if not totalClassDefinition.relations?
    ranges = totalClassDefinition.relations[key]?.range or []
    ranges = _.keys(ranges) if not _.isArray(ranges)
    (range for range in ranges)

  addSupers: (ids, total=[]) ->
    for id in ids
      total.push(id) if id not in total
      node = @classList[id]
      context = node.context
      definition = node.classDefinition

      if definition?.super?
        superId = context.getNodeNameByKey(definition.super)
        @addSupers([superId], total) if superId not in total
        
    total

  # getContextForNodeId: (id) ->
  #   [modelName, className] = id.split(':')
  #   @contextMap["#{modelName}@#{@loadMap[modelName]}"]

  getGraphName: ->
    console.warn('Deprecated function WeaverModel.getGraphName() used. Use WeaverModelContext.getGraph().')
    @getGraph()

  # Load given model from server
  @_loadDefinition: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

  @load: (name, version, includeList) ->
    WeaverModel._loadDefinition(name, version).then((model)->
      model.init(includeList)
    )

  @reload: (name, version, includeList) ->
    Weaver.getCoreManager().reloadModel(name, version).then((model)->
      model.init(includeList)
    )

  @list: ->
    Weaver.getCoreManager().listModels()

  getInheritKey: ->
    @definition.inherit or '_inherit'

  getMemberKey: ->
    @definition.member or '_member'

  getPrototypeKey: ->
    console.warn('Deprecated function WeaverModel.getPrototypeKey() used. Use WeaverModel.getMemberKey().')
    @getMemberKey()

  bootstrap: (project)->
    @_bootstrap(project)

  _bootstrap: (project, save=true)->
    existingNodes = {}

    Promise.map((context for tag, context of @contextMap), (context)=>
      new Weaver.Query(project)
      .contains('id', "#{context.definition.name}:")
      .restrictGraphs(context.getGraph())
      .find().then((nodes) =>
        existingNodes[n.id()] = n for n in nodes
      )
    ).then(=>
      nodesToCreate = @_bootstrapClasses(existingNodes)
      Weaver.Node.batchSave((node for id, node of nodesToCreate), project) if save
    )

  _bootstrapClasses: (existingNodes, nodesToCreate={}) ->

    firstOrCreate = (id, graph, Constructor=Weaver.Node, create=true) ->
      return nodesToCreate[id] if nodesToCreate[id]?
      if existingNodes[id]?
        node = existingNodes[id]
        nodesToCreate[id] = node
        return node
      throw new Error("Node #{id} in graph #{graph} should already exist in this phase of bootstrapping") if !create
      node = new Constructor(id, graph)
      nodesToCreate[id] = node
      node

    # First create all class instances
    for tag, context of @contextMap
      for className, classObj of context.definition.classes when classObj?.init?
        ownerId = context.getNodeNameByKey(className)
        owner = firstOrCreate(ownerId, context.getGraph())

        for itemName in classObj.init
          nodeId = "#{context.definition.name}:#{itemName}"
          node = firstOrCreate(nodeId, context.getGraph(), Weaver.DefinedNode)
          node.model = @
          node.relation(@getMemberKey()).add(owner)
          context[className][itemName] = node

      # Now add all the nodes that represent a model class
      for tag, context of @contextMap
        for className of context.definition.classes
          id = context.getNodeNameByKey(className)
          firstOrCreate(id, context.getGraph())

      # Link inheritance
      for tag, context of @contextMap
        for className, classObj of context.definition.classes when classObj?.super?
          id = context.getNodeNameByKey(className)
          superId = context.getNodeNameByKey(classObj.super)
          node = firstOrCreate(id, context.getGraph())
          superNode = firstOrCreate(superId, context.getGraph(), undefined, false)
          node.relation(@getInheritKey()).add(superNode)

    nodesToCreate

module.exports = WeaverModel
