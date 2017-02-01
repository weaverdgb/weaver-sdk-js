cuid       = require('cuid')
chirql     = require('Chirql')
Weaver     = require('./Weaver')
WeaverNode = require('./WeaverNode')
util       = require('./util')

Lexer = chirql.Lexer
Parser = chirql.Parser


class WeaverModel

  lexer: new Lexer()
  parser: new Parser()

  class ModelFragment

    constructor:(fragment)->

      definition:
        _id:            fragment.id or cuid()
        _props:
          isOptional:   fragment.isOptional or false
          isExcluded:   fragment.isExcluded or false
          cardinality:
            min:        fragment.cardinalityMin or 0
            max:        fragment.cardinalityMax or undefined
        _type:          fragment.type or throw new Error("Definition string invalid")
        _path:          path.concat(fragment.predicate)


  constructor: (@name, @definitionString)->

    @inputArgs = {}

    ###

      sample model:

      {
        definition: {
          _id: 'uuid'
          _props: {
            isOptional: bool
            isExcluded: bool
            cardinalityMin: num
            cardinalityMax: num
          }
          _type: 'Relation'/'Attribute'

          hasName: { new model here.. }
          hasBrother: { new model here.. }
          etc.
        }
        inputArgs: {
          argName: ['path', 'to', 'argument', 'pointer', 'relative', 'to', 'root', 'node']
        }
        definitionString: "Chirql string to define model"

        ..normal WeaverNode props (nodeId, etc..)
      }

    ###

  define: (@definitionString)->

    @definition = {}

    ###

     @inputArgs looks like this: { $variableName : ['path','to','this','variable','from','root','node']

     these are the required arguments for a modelInstance instance. eg if a model definition has `<hasName>($name)`,
     then a modelInstance of that model should define a value for `$name` before saving

    ###

    @inputArgs = {}

    tokens = @lexer.lex(@definitionString)
    fragmentList = @parser.parseTokens(tokens)

    # stores and removes root node id, if specified
    if fragmentList[0] isnt 'OPEN_BLOCK'
      @inputArgs['rootId'] = fragmentList[0]
      fragmentList.shift()

    parseOneLevel = (arr, path)=>

      returnObj = {}
      openedBlocks = 0
      fragments = arr.slice(1,-1)

      for fragment,i in fragments

        if openedBlocks > 0

    parseOneLevel()

  modelInstance: ->
    new ModelInstance(@definition, @inputArgs)


class ModelInstance

  constructor: (@modelDefinition, @inputArgs)->

    @instance = {}
    @instance[i] = j for i, j of @modelDefinition when i isnt 'inputArgs'

  set: (propPath, value)->

    throw new Error("Value property/Attribute strings cannot contain the character '@'.") if value.indexOf('@') isnt -1
    throw new Error("Input argument strings cannot contain the character '$'.")           if value.indexOf('$') isnt -1
    throw new Error(propPath + " is not a valid input argument for this model.")          if not @inputArgs[propPath]

    path = @inputArgs[propPath]

    checkPathValidity(@inputArgs[propPath], @modelDefinition, 'Value')

    pointer = @instance
    pointer = pointer[p] for p in path.slice(0, -1)
    pointer[path.slice(-1)[0]] = '@' + value

  add: (propPath, value)->

    throw new Error(propPath + ' is not a valid input argument for this model') if not @inputArgs[propPath]

    path = @inputArgs[propPath]

    checkPathValidity(@inputArgs[propPath], @modelDefinition, 'Individual')

    pointer = @instance
    pointer = pointer[p] for p in path.slice(0, -1)

    pointer[path.slice(-1)[0]] = [] if pointer[path.slice(-1)[0]][0].indexOf('$') is 0

    pointer[path.slice(-1)[0]].push(value)

  save: ->

    promises = []
    nodes = []

    new Promise((resolve,reject)=>

      throwUnsetArgsException = ->
        reject(new Error('This model instance has unset input arguments. All input arguments must be set before saving.'))

      if @inputArgs['rootId']
        root = new Weaver.Node(@inputArgs['rootId'])
      else
        root = new Weaver.Node()

      nodes.push(root)

      persistOneLevel = (parent, props)->

        for key,prop of props

          if util.isObject(prop)

            child = new Weaver.Node()
            nodes.push(child)

            persistOneLevel(child, prop)
            parent.relation(key).add(child)

          else

            throwUnsetArgsException() if prop.indexOf('$') isnt -1

            parent.set(key, prop.slice(1)) if prop.indexOf('@') isnt -1

            if util.isArray(prop)

              for id in prop

                if id is 'RANDOM'
                  indiProp = new Weaver.Node()
                  parent.relation(key).add(indiProp)

                else

                  promises.push(
                    new Promise((resolve,reject)->
                      shallowKey = key

                      Weaver.Node.load(id).then((res)->
                        parent.relation(shallowKey).add(res)
                        parent.save()
                        resolve(parent)
                      ).catch((err)->
                        reject(err)
                      )
                    )
                  )

      persistOneLevel(root, @instance)

      promises.push(node.save()) for node in nodes

      Promise.all(promises).then((res)->

        #return the root node, which should always be at index 0
        resolve(res[0])
      )

    )

  checkPathValidity = (path, model, propType)->

    pointer = model
    pointer = pointer[p] for p in path.slice(0, -1)

    loc = pointer[path.slice(-1)[0]]

    if propType is 'Individual' and not util.isArray(loc)
      throw new Error("Cannot use 'add' to set attribute. Use 'set' instead.")

    if propType is 'Value' and util.isArray(loc)
      throw new Error("Cannot use 'set' to add relation. Use 'add' instead.")

module.exports = WeaverModel
