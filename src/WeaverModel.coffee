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

module.exports = WeaverModel
