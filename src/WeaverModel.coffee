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

    @graphName = "#{@definition.name}-#{@definition.version}"


  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

  @reload: (name, version) ->
    Weaver.getCoreManager().reloadModel(name, version)

  getInheritKey: ->
    @definition.inherit or '_inherit'

  bootstrap: ->
    new Weaver.Query()
    .contains('id', "#{@definition.name}:")
    .restrictGraphs(@graphName)
    .find().then((nodes) =>
      @_bootstrapClasses((i.id() for i in nodes), modelGraph)
    )

  _bootstrapClasses: (existingNodes) ->
    nodesToCreate = {}

    for className of @definition.classes when not existingNodes.includes("#{@definition.name}:#{className}")
      node = new Weaver.Node("#{@definition.name}:#{className}", @graphName)
      nodesToCreate[node.id()] = node

    for className, classObj of @definition.classes when classObj.init? and not existingNodes.includes("#{@definition.name}:#{className}")
      ModelClass = @[className]
      for itemName in classObj.init when not existingNodes.includes("#{@definition.name}:#{itemName}")
        nodesToCreate["#{@definition.name}:#{itemName}"] = new ModelClass("#{@definition.name}:#{itemName}", graph)

    for className, classObj of @definition.classes when classObj.super? and not existingNodes.includes("#{@definition.name}:#{className}")
      modelClassNode = nodesToCreate["#{@definition.name}:#{className}"]
      superClassNode = Weaver.Node.getFromGraph("#{@definition.name}:#{classObj.super}", @graphName)
      modelClassNode.relation(@getInheritKey()).add(superClassNode)

    Weaver.Node.batchSave(node for id, node of nodesToCreate)


module.exports = WeaverModel
