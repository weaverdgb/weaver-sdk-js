cuid        = require('cuid')
Promise     = require('bluebird')
Weaver      = require('./Weaver')

class WeaverModel

  constructor: (@definition) ->
    
    # Register classes
    for modelClass in @definition.classes
      name = Object.keys(modelClass)[0]

      js = """
        (function() {
          function #{name}() {}

          #{name}.defineBy = function(modelClass) {
            this.modelClass = modelClass;
          };

          return #{name};

        })();
      """

      @[name] = eval(js)
      @[name] = @[name] extends Weaver.ModelClass
      @[name].defineBy(modelClass)


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
      for modelClassName in (Object.keys(i)[0] for i in@definition.classes)
        if !existingDatabaseClasses.includes("#{@definition.name}:#{modelClassName}")
          new Weaver.Node("#{@definition.name}:#{modelClassName}").save()
    )

module.exports = WeaverModel
