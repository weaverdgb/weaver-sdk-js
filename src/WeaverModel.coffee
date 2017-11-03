cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModel

  constructor: (@definition) ->
    # Register classes
    for className, classDefinition of @definition.classes

      js = """
        (function() {
          function #{className}(nodeId) {
            this.model           = #{className}.model;
            this.definition      = #{className}.definition;
            this.classDefinition = #{className}.classDefinition;
            #{className}.__super__.constructor.call(this, nodeId);
          };

          #{className}.defineBy = function(model, definition, classDefinition) {
            this.model           = model;
            this.definition      = definition;
            this.classDefinition = classDefinition;
          };

          return #{className};
        })();
      """

      @[className] = eval(js)
      @[className] = @[className] extends Weaver.ModelClass
      @[className].defineBy(@, @definition, classDefinition)


  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

  bootstrap: ->
    new Weaver.Query()
    .contains('id', "#{@definition.name}:")
    .find().then((classes) =>
      @_bootstrapClasses(i.id() for i in classes)
    )

  _bootstrapClasses: (existingDatabaseClasses) ->
    Promise.all(
      for modelClassName of @definition.classes
        if !existingDatabaseClasses.includes("#{@definition.name}:#{modelClassName}")
          new Weaver.Node("#{@definition.name}:#{modelClassName}").save()
    )

module.exports = WeaverModel
