cuid                 = require('cuid')
Promise              = require('bluebird')
semver               = require('semver')
Weaver               = require('./Weaver')
WeaverModelValidator = require('./WeaverModelValidator')
_                    = require('lodash')

class WeaverModel

  constructor: (@definition) ->
    @_graph = "#{@definition.name}-#{semver.major(@definition.version)}"

  init: (includeList)->

    # Load included models
    includeList = [] if not includeList?
    includeList.push(@definition.name)
    @modelMap = {}
    @modelMap[@definition.name] = @
    @_loadIncludes(includeList, @modelMap).then(=>

      new WeaverModelValidator(@definition, @includes).validate()
      for className, classDefinition of @definition.classes
        @_registerClass(@, @, className, classDefinition)
      for prefix, incl of @includes
        @[prefix] = {}
        for className, classDefinition of incl.definition.classes
          if @modelMap[incl.definition.name]?[className]?
            @[prefix][className] = @modelMap[incl.definition.name][className]
          else
            @_registerClass(@[prefix], incl, className, classDefinition)
      @
    )

  _registerClass: (carrier, model, className, classDefinition)->

    js = """
      (function() {
        var #{className} = class #{className} extends Weaver.ModelClass {
          constructor(nodeId, graph) {
            super(nodeId, graph, #{className}.model)
            this.model                = #{className}.model;
            this.definition           = #{className}.definition;
            this.className            = "#{className}";
            this.classDefinition      = #{className}.classDefinition;
            this.totalClassDefinition = #{className}.totalClassDefinition;
          }
          classId() {
            return #{className}.definition.name + ":" + #{className}.className;
          };
        };

        return #{className};
      })();
    """

    carrier[className] = eval(js)
    carrier[className].model                = model
    carrier[className].definition           = model.definition
    carrier[className].className            = className
    carrier[className].classDefinition      = classDefinition
    carrier[className].totalClassDefinition = model._collectFromSupers(classDefinition)

    load = (loadClass) => (nodeId, graph) =>
      new Weaver.ModelQuery(model)
        .class(carrier[loadClass])
        .restrict(nodeId)
        .first(carrier[loadClass])

    carrier[className].load = load(className)


  _loadIncludes: (includeList, modelMap)->
    @definition.includes = {} if not @definition.includes?

    # Map prefix to included model
    @includes = {}
    includeDefs = ({prefix: key, name: obj.name, version: obj.version} for key, obj of @definition.includes)

    Promise.map(includeDefs, (incl)=>
      if incl.name in includeList
        error = new Error("Model #{@definition.name} tries to include #{incl.name} but this introduces a cycle")
        error.code = 209
        return Promise.reject(error)

      WeaverModel.load(incl.name, incl.version, includeList).then((loaded)=>
        @includes[incl.prefix] = loaded
        modelMap[incl.name] = loaded
      )
    )

  _collectFromSupers: (classDefinition)->
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
                updated = @getNodeNameByKey(range)
                updatedRanges.push(updated)
              totalDefinition[source][k].range = updatedRanges

      transfer('attributes')
      transfer('relations')

      totalDefinition

    addFromSuper(classDefinition)


  # eg test-model:td.Document is processed from [test-model:td][Document] to [test-doc-model][Document]
  getNodeNameByKey: (dotPath) ->
    [first, rest...] = dotPath.split('.')
    return "#{@definition.name}:#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') < 0
    return "#{dotPath}" if rest.length is 0 and dotPath.indexOf(':') >= 0

    if first.indexOf(':') < 0
      if @includes[first]?
        m = @includes[first]
        return m.getNodeNameByKey(rest.join('.'))
    else
      [modelName, prefix] = first.split(':')
      if @modelMap[modelName]? and @modelMap[modelName].includes[prefix]?
        m = @modelMap[modelName].includes[prefix]
        return m.getNodeNameByKey(rest.join('.'))

    return null

  getGraphName: ->
    console.warn('Deprecated function WeaverModel.getGraphName() used. Use WeaverModel.getGraph().')
    @_graph

  getGraph: ->
    @_graph

  # Load given model from server
  @load: (name, version, includeList) ->
    Weaver.getCoreManager().getModel(name, version).then((model)->
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
    # Bootstrap the include models in bottom up order because first order models can extend concepts from included models
    Promise.all((incl._bootstrap(project, false) for prefix, incl of @includes))
    .then((resList)=>

      existingNodes = {}
      existingNodes[id] = node for id, node of res.existingNodes for res in resList

      nodesToCreate = {}
      nodesToCreate[id] = node for id, node of res.nodesToCreate for res in resList

      new Weaver.Query(project)
      .contains('id', "#{@definition.name}:")
      .find().then((nodes) =>
        existingNodes[n.id()] = n for n in nodes
        resList = @_bootstrapClasses(existingNodes, nodesToCreate)
        nodesToCreate = resList.nodesToCreate
        existingNodes = resList.existingNodes

        if save
          Weaver.Node.batchSave((node for id, node of nodesToCreate), project)
        else
          {nodesToCreate, existingNodes}
      )
    )

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
