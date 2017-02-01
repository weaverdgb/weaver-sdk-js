chirql     = require('Chirql')
Weaver     = require('./Weaver')
WeaverNode = require('./WeaverNode')
util       = require('./util')

Lexer = chirql.Lexer
Parser = chirql.Parser


class WeaverModel extends WeaverNode

  constructor: (@name)->

    @lexer = new Lexer()
    @parser = new Parser()

    @modelInstance = =>
      new ModelInstance(@definition, @inputArgs)

    @define = (@definitionString)=>

      tokens = @lexer.lex(@definitionString)
      fragmentList = @parser.parseTokens(tokens)

      @definition = {}

      # these are the required arguments for a modelInstance instance. eg if a model definition has `<hasName>($name)`,
      # then a modelInstance of that model should define a value for `$name` before saving
      @inputArgs = {}
      # @inputArgs looks like this: { $variableName : ['path','to','this','variable','from','root','node']

      parseInnerLevel = (returnObj, fragments, start, end, path)->

        innerBlock = fragments.slice(start, end)
        preceedingSubject = fragments[parseInt(start)-1]
        newPath = path.concat(preceedingSubject.predicate)
        returnObj[preceedingSubject.predicate] = parseOneLevel(innerBlock, newPath)

      parseOneLevel = (arr, path)=>  # parse one block of chirql code

        returnObj = {}
        openedBlocks = 0

        # removes outer brace tokens
        if arr[0] is 'OPEN_BLOCK'
          fragments = arr.slice(1,-1)

        else # runs when the root block has a specified id
          fragments = arr.slice(2,-1)
          @inputArgs['rootId'] = arr[0]

        for fragment,i in fragments

          if fragment is 'CLOSE_BLOCK'

            if openedBlocks is 1

              endBlock = i+1
              parseInnerLevel(returnObj, fragments, startBlock, endBlock, path)

            openedBlocks--

          if fragment == 'OPEN_BLOCK'

            startBlock = i if openedBlocks is 0
            openedBlocks++

          if openedBlocks is 0

            if fragment.inputArg
              @inputArgs[fragment.object] = path.concat(fragment.predicate)

            if fragment.object

              if fragment.type is 'Individual'
                returnObj[fragment.predicate] = [ fragment.object ]
              else

                throw new Error('Value property/Attribute strings cannot contain \'@\'') if fragment.object.indexOf('@') isnt -1
                returnObj[fragment.predicate] = '@' + fragment.object

            else
              returnObj[fragment.predicate] = ['RANDOM'] if fragment.type is 'Individual'
              returnObj[fragment.predicate] = '@EMPTY' if fragment.type is 'Value'

        returnObj

      definition = parseOneLevel(fragmentList, [])

      @definition = definition

class ModelInstance

  constructor: (@modelDefinition, @inputArgs)->

    @instance = {}
    @instance[i] = j for i, j of @modelDefinition when i isnt 'inputArgs'

    checkPathValidity = (path, model, propType)->

      pointer = model
      pointer = pointer[p] for p in path.slice(0, -1)

      loc = pointer[path.slice(-1)[0]]

      if propType is 'Individual' and not util.isArray(loc)
        throw new Error("Cannot use 'add' to set attribute. Use 'set' instead.")

      if propType is 'Value' and util.isArray(loc)
        throw new Error("Cannot use 'set' to add relation. Use 'add' instead.")


    @set = (propPath, value)=>

      throw new Error("Value property/Attribute strings cannot contain the character '@'.") if value.indexOf('@') isnt -1
      throw new Error("Input argument strings cannot contain the character '$'.")           if value.indexOf('$') isnt -1
      throw new Error(propPath + " is not a valid input argument for this model.")          if not @inputArgs[propPath]

      path = @inputArgs[propPath]

      checkPathValidity(@inputArgs[propPath], @modelDefinition, 'Value')

      pointer = @instance
      pointer = pointer[p] for p in path.slice(0, -1)
      pointer[path.slice(-1)[0]] = '@' + value


    @add = (propPath, value)=>

      throw new Error(propPath + ' is not a valid input argument for this model') if not @inputArgs[propPath]

      path = @inputArgs[propPath]

      checkPathValidity(@inputArgs[propPath], @modelDefinition, 'Individual')

      pointer = @instance
      pointer = pointer[p] for p in path.slice(0, -1)

      pointer[path.slice(-1)[0]] = [] if pointer[path.slice(-1)[0]][0].indexOf('$') is 0

      pointer[path.slice(-1)[0]].push(value)

    @save = ->

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

module.exports = WeaverModel
