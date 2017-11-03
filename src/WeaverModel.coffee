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
            this.definition      = #{className}.definition;
            this.classDefinition = #{className}.classDefinition;
            #{className}.__super__.constructor.call(this, nodeId);
          }

          #{className}.defineBy = function(definition, classDefinition) {
            this.definition      = definition;
            this.classDefinition = classDefinition;
          };

          return #{className};

        })();
      """

      @[className] = eval(js)
      @[className] = @[className] extends Weaver.ModelClass
      @[className].defineBy(@definition, classDefinition)


  # Load given model from server
  @load: (name, version) ->
    Weaver.getCoreManager().getModel(name, version)

module.exports = WeaverModel
