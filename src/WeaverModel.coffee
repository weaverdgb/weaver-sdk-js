cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')
WeaverModelValidator = require('./WeaverModelValidator')

class WeaverModel

  constructor: (@definition) ->
    new WeaverModelValidator(@definition).validate()

    # Register classes
    for className, classDefinition of @definition.classes

      js = """
        (function() {
          function #{className}(nodeId) {
            this.model           = #{className}.model;
            this.definition      = #{className}.definition;
            this.className       = "#{className}";
            this.classDefinition = #{className}.classDefinition;
            this.class           = #{className};
            #{className}.__super__.constructor.call(this, nodeId);
          };

          #{className}.defineBy = function(model, definition, className, classDefinition) {
            this.model           = model;
            this.definition      = definition;
            this.className       = className;
            this.classDefinition = classDefinition;
          };

          #{className}.classId = function(){
            return #{className}.definition.name + ":" + #{className}.className
          };

          return #{className};
        })();
      """

      @[className] = eval(js)
      @[className] = @[className] extends Weaver.ModelClass
      @[className].defineBy(@, @definition, className, classDefinition)
      load = (loadClass) => (nodeId) =>
        new Weaver.ModelQuery(@)
          .class(@[loadClass])
          .restrict(nodeId)
          .inGraph(@getGraphName())
          .first()

      @[className].load = load(className)

    @_graphName = "#{@definition.name}-#{@definition.version}"

  getGraphName: ->
    @_graphName

  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

  @reload: (name, version) ->
    Weaver.getCoreManager().reloadModel(name, version)

  getInheritKey: ->
    @definition.inherit or '_inherit'

  getMemberKey: ->
    @definition.member or '_member'

  bootstrap: ->
    new Weaver.Query()
    .contains('id', "#{@definition.name}:")
    .restrictGraphs(@getGraphName())
    .find().then((nodes) =>
      @_bootstrapClasses((i.id() for i in nodes))
    )

  _bootstrapClasses: (existingNodes) ->
    nodesToCreate = {}

    for className of @definition.classes when not existingNodes.includes("#{@definition.name}:#{className}")
      node = new Weaver.Node("#{@definition.name}:#{className}", @getGraphName())
      nodesToCreate[node.id()] = node

    for className, classObj of @definition.classes when classObj.init? and not existingNodes.includes("#{@definition.name}:#{className}")
      ModelClass = @[className]
      for itemName in classObj.init when not existingNodes.includes("#{@definition.name}:#{itemName}")
        if @[itemName]?
          # This is a member that is also a class
          itemNode = nodesToCreate["#{@definition.name}:#{itemName}"]
          # So add the member definition
          itemNode.relation(@definition.member).addInGraph(nodesToCreate["#{@definition.name}:#{className}"], @getGraphName)
          @[className][itemName] = itemNode
        else
          node = new ModelClass("#{@definition.name}:#{itemName}")
          @[className][itemName] = node
          nodesToCreate["#{@definition.name}:#{itemName}"] = node

    for className, classObj of @definition.classes when classObj.super? and not existingNodes.includes("#{@definition.name}:#{className}")
      modelClassNode = nodesToCreate["#{@definition.name}:#{className}"]
      superClassNode = Weaver.Node.getFromGraph("#{@definition.name}:#{classObj.super}", @getGraphName())
      modelClassNode.relation(@getInheritKey()).add(superClassNode)

    Weaver.Node.batchSave(node for id, node of nodesToCreate)


module.exports = WeaverModel
