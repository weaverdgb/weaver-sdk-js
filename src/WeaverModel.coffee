cuid                 = require('cuid')
Promise              = require('bluebird')
semver               = require('semver')
Weaver               = require('./Weaver')
ModelContext         = require('./WeaverModelContext')
ModelValidator       = require('./WeaverModelValidator')
WeaverError          = require('./Error')
_                    = require('lodash')

class WeaverModel extends ModelContext

  constructor: (definition) ->
    super(definition)
    @_graph = "#{@definition.name}-#{semver.major(@definition.version)}"

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
        # Attach included models to context
        for prefix, incl of context.definition.modelPrefixes
          context[prefix] = @contextMap[incl.tag]
        # Attach classes to context
        for className, classDefinition of context.definition.classes
          @_registerClass(context, className, classDefinition) if context.isNativeClass(className)
          
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
    modelClass.totalClassDefinition = @_collectFromSupers(classDefinition, context)
    modelClass.totalRangesMap       = @_buildRanges(modelClass.totalClassDefinition, context)
    modelClass.classId              = -> @.context.getNodeNameByKey(@.className)

    # Also undefind is a valid as agrument for graph
    load = (loadClass) => (nodeId, graph) =>
      query = new Weaver.ModelQuery(@)
      .class(context[loadClass])
      .restrict(nodeId)
      query.restrictGraphs([graph]) if arguments.length > 1
      query.first(context[loadClass])

    modelClass.load = load(className)

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

      @loadMap[inc.name] = inc.version

      # Deprecated
      @includes[obj.prefix] = @
      @modelMap[obj.name] = @

      WeaverModel._loadDefinition(obj.name, obj.version)
      .then((def)=>
        @contextMap[obj.tag] = new ModelContext(def)
        @_loadIncludes(def)
      )
    )

  _collectFromSupers: (classDefinition, context)->
    addFromSuper = (cd, definition = @definition, totalDefinition = {attributes: {}, relations: {}}) =>

      # Start with supers so lower specifications override the super ones
      if cd?.super?
        def = definition
        className = cd.super
        if cd.super.indexOf('.') > -1
          [prefix, className] = cd.super.split('.')
          def = @includes[prefix].definition
        superDefinition = def.classes[className]
        addFromSuper(superDefinition, def, totalDefinition)

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

    addFromSuper(classDefinition)


  _buildRanges: (totalClassDefinition) ->
    map = {}
    map[key] = @_getRanges(key, totalClassDefinition) for key, obj of totalClassDefinition.relations
    map

  _getRanges: (key, totalClassDefinition)->

    addSubRange = (range, ranges = []) =>

      for modelTag, context of @contextMap
        for className, definition of context.definition.classes
          if definition?.super?
            superClassName = context.getNodeNameByKey(definition.super)
            if superClassName is range
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
    console.warn('Deprecated function WeaverModel.getGraphName() used. Use WeaverModel.getGraph().')
    @_graph

  getGraph: ->
    @_graph

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

  # get id of node for className
  _getClassNodeId: (key)->

    # look in included models if needed
    if key.indexOf('.') > -1
      prefix = key.substr(0, key.indexOf('.'))
      tail = key.substr(key.indexOf('.') + 1)
      if not @includes[prefix]?
        throw new Error("Using prefix #{prefix} in #{key} but not including a model using this prefix.")
      modelName = @includes[prefix].definition.name
      "#{modelName}:#{tail}"

    # look in the main model
    else
      modelName = @definition.name
      "#{modelName}:#{key}"

  bootstrap: (project)->
    @_bootstrap(project)

  _bootstrap: (project, save=true)->
    # # Bootstrap the include models in bottom up order because first order models can extend concepts from included models
    # Promise.all((incl._bootstrap(project, false) for prefix, incl of @includes))
    # .then((resList)=>

    #   existingNodes = {}
    #   existingNodes[id] = node for id, node of res.existingNodes for res in resList

    #   nodesToCreate = {}
    #   nodesToCreate[id] = node for id, node of res.nodesToCreate for res in resList

    #   new Weaver.Query(project)
    #   .contains('id', "#{@definition.name}:")
    #   .restrictGraphs(@getGraph())
    #   .find().then((nodes) =>
    #     existingNodes[n.id()] = n for n in nodes
    #     resList = @_bootstrapClasses(existingNodes, nodesToCreate)
    #     nodesToCreate = resList.nodesToCreate
    #     existingNodes = resList.existingNodes

    #     if save
    #       Weaver.Node.batchSave((node for id, node of nodesToCreate), project)
    #     else
    #       {nodesToCreate, existingNodes}
    #   )
    # )
    Promise.resolve()

  _bootstrapClasses: (existingNodes, nodesToCreate={}) ->

    # First create all class instances
    for className, classObj of @definition.classes when classObj.init?
      ModelClass = @[className]

      for itemName in classObj.init
        node = new ModelClass("#{@definition.name}:#{itemName}", @getGraph())
        if !existingNodes["#{@definition.name}:#{itemName}"]?
          nodesToCreate[node.id()] = node
        else
          node._clearPendingWrites()
        @[className][itemName] = node

    # Now add all the nodes that are not a model class
    for className of @definition.classes
      id = @_getClassNodeId(className)
      if !existingNodes[id]?
        if not nodesToCreate[id]?
          node = new Weaver.Node(id, @getGraph())
          nodesToCreate[node.id()] = node

    # Link inheritance
    for className, classObj of @definition.classes when classObj.super?
      id = @_getClassNodeId(className)
      superId = @_getClassNodeId(classObj.super)
      if !existingNodes[id]?
        node = nodesToCreate[id]
        superClassNode = nodesToCreate[superId] or existingNodes[superId] or throw new Error("Failed linking to super node #{superId}")
        if node instanceof Weaver.ModelClass
          node.nodeRelation(@getInheritKey()).add(superClassNode)
        else
          node.relation(@getInheritKey()).add(superClassNode)

    {nodesToCreate, existingNodes}

module.exports = WeaverModel
