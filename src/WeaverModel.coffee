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


  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

  @reload: (name, version) ->
    Weaver.getCoreManager().reloadModel(name, version)

  bootstrap: (graph)->
    modelGraph = if graph? then graph else @definition.name
    new Weaver.Query()
    .restrictGraphs(modelGraph)
    .contains('id', "#{@definition.name}:")
    .find().then((nodes) =>
      @_bootstrapClasses((i.id() for i in nodes), modelGraph)
    )

  _bootstrapClasses: (existingNodes, graph) ->
    promises = []
    nodesToCreate = {}

    for modelClassName of @definition.classes when not existingNodes.includes("#{@definition.name}:#{modelClassName}")
      node = new Weaver.Node("#{@definition.name}:#{modelClassName}", graph)
      nodesToCreate[node.id()] = node

    for className, classObj of @definition.classes when classObj.init?
      ModelClass = @[className]
      for itemName in classObj.init when not existingNodes.includes("#{@definition.name}:#{itemName}")
        nodesToCreate["#{@definition.name}:#{itemName}"] = new ModelClass("#{@definition.name}:#{itemName}", graph)

    promises.push(node.save()) for id, node of nodesToCreate

    Promise.all(promises)


module.exports = WeaverModel
