cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
WeaverModelValidator = require('./WeaverModelValidator')

class WeaverModel

  constructor: (@definition, includeList) ->
  
    # Load included models
    includeList = [] if not includeList?
    includeList.push(@definition.name)
    @_loadIncludes(includeList).then(=>

      new WeaverModelValidator(@definition, @includes).validate()
      @_registerClasses()
    )

  _registerClasses: ->
  
    for className, classDefinition of @definition.classes

      js = """
        (function() {
          function #{className}(nodeId, graph) {
            this.model                = #{className}.model;
            this.definition           = #{className}.definition;
            this.className            = "#{className}";
            this.classDefinition      = #{className}.classDefinition;
            this.totalClassDefinition = #{className}.totalClassDefinition;
            #{className}.__super__.constructor.call(this, nodeId, graph);
          };

          #{className}.defineBy = function(model, definition, className, classDefinition, totalClassDefinition) {
            this.model                = model;
            this.definition           = definition;
            this.className            = className;
            this.classDefinition      = classDefinition;
            this.totalClassDefinition = totalClassDefinition;
          };

          #{className}.classId = function() {
            return #{className}.definition.name + ":" + #{className}.className;
          };

          return #{className};
        })();
      """



      _collectFromSupers = (classDefinition)=>
        addFromSuper = (cd, totalDefinition = {attributes: {}, relations: {}}) =>

          # Start with supers so lower specifications override the super ones
          if cd.super?
            superDefinition = @definition.classes[cd.super]
            addFromSuper(superDefinition, totalDefinition)

          transfer = (source) ->
            totalDefinition[source][k] = v for k, v of cd[source] if cd[source]?

          transfer('attributes')
          transfer('relations')

          totalDefinition

        addFromSuper(classDefinition)


      totalClassDefinition = _collectFromSupers(classDefinition)

      @[className] = eval(js)
      @[className] = @[className] extends Weaver.ModelClass
      @[className].defineBy(@, @definition, className, classDefinition, totalClassDefinition)
      load = (loadClass) => (nodeId, graph) =>
        new Weaver.ModelQuery(@)
          .class(@[loadClass])
          .restrict(nodeId)
          .inGraph(graph)
          .first(@[loadClass])

      @[className].load = load(className)

    @_graph = "#{@definition.name}-#{@definition.version}"

  _loadIncludes: (includeList)->
    @definition.includes = {} if not @definition.includes?

    # Map prefix to included model
    @includes = {}
    includeDefs = ({prefix: key, name: obj.name, version: obj.version} for key, obj of @definition.includes)
    Promise.map(includeDefs, (incl)=>
      if incl.name in includeList
        throw new Error("Model #{@definition.name} tries to include #{incl.name} but this introduces a cycle") 
      WeaverModel.load(incl.name, incl.version, includeList).then((loaded)=>
        @includes[incl.prefix] = loaded
      )
    )


  getGraphName: ->
    console.warn('Deprecated function WeaverModel.getGraphName() used. Use WeaverModel.getGraph().')
    @_graph

  getGraph: ->
    @_graph

  # Load given model from server
  @load: (name, version, includeList) ->
    Weaver.getCoreManager().getModel(name, version, includeList)

  @reload: (name, version) ->
    Weaver.getCoreManager().reloadModel(name, version)

  @list: ->
    Weaver.getCoreManager().listModels()

  getInheritKey: ->
    @definition.inherit or '_inherit'

  getMemberKey: ->
    @definition.member or '_member'

  getPrototypeKey: ->
    console.warn('Deprecated function WeaverModel.getPrototypeKey() used. Use WeaverModel.getMemberKey().')
    @getMemberKey()

  bootstrap: ->
    new Weaver.Query()
    .contains('id', "#{@definition.name}:")
    .restrictGraphs(@getGraph())
    .find().then((nodes) =>
      @_bootstrapClasses((i.id() for i in nodes))
    )

  _bootstrapClasses: (existingNodes) ->
    nodesToCreate = {}

    # First create all class instances
    for className, classObj of @definition.classes when classObj.init?
      ModelClass = @[className]

      for itemName in classObj.init
        node = new ModelClass("#{@definition.name}:#{itemName}", @getGraph())
        if not existingNodes.includes("#{@definition.name}:#{itemName}")
          nodesToCreate[node.id()] = node
        else
          node._clearPendingWrites()
        @[className][itemName] = node

    # Now add all the nodes that are not a model class
    for className of @definition.classes when not existingNodes.includes("#{@definition.name}:#{className}")
      id = "#{@definition.name}:#{className}"
      if not nodesToCreate[id]?
        node = new Weaver.Node(id, @getGraph())
        nodesToCreate[node.id()] = node

    # Link inheritance
    for className, classObj of @definition.classes when classObj.super? and not existingNodes.includes("#{@definition.name}:#{className}")
      node = nodesToCreate["#{@definition.name}:#{className}"]
      superClassNode = nodesToCreate["#{@definition.name}:#{classObj.super}"] 
      if node instanceof Weaver.ModelClass
        node.nodeRelation(@getInheritKey()).add(superClassNode)
      else
        node.relation(@getInheritKey()).add(superClassNode)

    Weaver.Node.batchSave(node for id, node of nodesToCreate)

module.exports = WeaverModel
