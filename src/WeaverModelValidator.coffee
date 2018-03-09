class WeaverModelValidator

  constructor: (@definition, @includes) ->

  isClass: (key)->
    if key.indexOf('.') > -1
      prefix = key.substr(0, key.indexOf('.'))
      tail = key.substr(key.indexOf('.') + 1)
      if not @includes[prefix]?
        throw new Error("Using prefix #{prefix} in #{key} but not including a model using this prefix.")
      @includes[prefix].definition.classes[tail]?
    else
      @definition.classes[key]?


  validate: ->
    for className of @definition.classes
      # Set nulls to {}
      @definition.classes[className] = @definition.classes[className] or {}
      classDefinition = @definition.classes[className]

      # Check if super is available
      if classDefinition.super?
        if not @isClass(classDefinition.super)
          throw new Error("Super class #{classDefinition.super} for #{className} could not be found in the definition.")

      # Check if range in relations exist
      for key, relation of classDefinition.relations when relation?.range?
        for range in relation.range
          if not @isClass(range)
            throw new Error("Range #{range} in relation #{className}.#{key} could not be found in the definition.")


module.exports = WeaverModelValidator
