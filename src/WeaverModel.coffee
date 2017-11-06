cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModel

  constructor: (@definition) ->

    # Set nulls to {}
    for className, classDefinition of @definition.classes when classDefinition is null
      @definition.classes[className] = {}

    # Register classes
    for className, classDefinition of @definition.classes

      # Check if super is available
      if classDefinition.super?
        superDefinition = @definition.classes[classDefinition.super]
        if not superDefinition?
          throw new Error("Super class #{classDefinition.super} for #{className} could not be found in the definition.")

      # TODO: Check if range exist and throw error otherwise
      # TODO: Better to move these validation codes into a ModelValidator.coffee
      
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
