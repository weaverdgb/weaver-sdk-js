cuid = require('cuid')

module.exports =
  class WeaverEntity
    
    typeIsArray = Array.isArray || ( value ) ->
      return {}.toString.call( value ) is '[object Array]'

    constructor: (object,id) ->
      attributes = []
      if typeof object is 'string' and not id
        @id = object
      else
        for key, value of object
          attribute = {}
          if key is 'id'
            attributes[attributes.length-1].id = value
          else
            attribute.key = key
            attribute.value = value
            attributes.push(attribute)
        if id
          if typeof id is 'object'
            @id = id.id
          else
            @id = id
        else
          @id = cuid()
      if attributes.length != 0
        @attributes = attributes
        
    relate: (source, relationTarget) ->
      relations = []
      for key, value of relationTarget
        relation = {}
        relation.relation = key
        if typeof value is 'string'
          relation.target = value
        if typeof value is 'object'
          relation.target = value.id
        if typeIsArray value
          relation.target = value
        relations.push(relation)
        
      for relation, index in relations
        if typeIsArray relation.target
          delete relations[index]
          # relations.splice(index, index)
          for tar in relation.target
            rel = {}
            rel.relation = relation.relation
            rel.target = tar
            relations.push(rel)
            
      if typeof source is 'string'
        @id = source
      else
        @id = source.id
      if relations.length != 0
        @relations = relations
      @
