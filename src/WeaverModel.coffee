chirql     = require('Chirql')
Weaver     = require('./Weaver')

Lexer = chirql.Lexer
Parser = chirql.Parser


class WeaverModel

  constructor: (@name)->

    @lexer = new Lexer()
    @parser = new Parser()

    @instance = =>
      new ModelInstance(@definition, @inputArgs)

    @define = (@definitionString)=>

      tokens = @lexer.lex(@definitionString)
      fragmentList = @parser.parseTokens(tokens)
      @definition = {}
      @inputArgs = {}

      parseOneLevel = (arr, path)=>

        returnObj = {}
        if arr[0] is 'OPEN_BLOCK'
          fragments = arr.slice(1,arr.length-1)
        else
          fragments = arr.slice(2,arr.length-1)
          @inputArgs['rootId'] = arr[0]


        openedBlocks = 0

        for fragment,i in fragments

          if fragment == 'CLOSE_BLOCK'

            if openedBlocks == 1

              innerBlock = fragments.slice(startBlock, i+1)
              preceedingSubject = fragments[parseInt(startBlock)-1]
              newPath = path.concat(preceedingSubject.predicate)
              returnObj[preceedingSubject.predicate] = parseOneLevel(innerBlock, newPath)

            openedBlocks--

          if fragment == 'OPEN_BLOCK'

            startBlock = i if openedBlocks == 0

            openedBlocks++

          if openedBlocks == 0

            if fragment and fragment.type

              if fragment.inputArg
                @inputArgs[fragment.object] = path.concat(fragment.predicate)

              if fragment.object

                throw new Error('Value property/Attribute strings cannot contain \'@\'') if fragment.object.indexOf('@') isnt -1

                if fragment.type is 'Individual'
                  returnObj[fragment.predicate] = [ fragment.object ]
                else
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

    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
    typeIsObject = Object.isObject || ( value ) -> return {}.toString.call( value ) is '[object Object]'


    checkPathValidity = (path, model, propType)->

      pointer = model
      pointer = pointer[p] for p in path.slice(0, -1)

      loc = pointer[path.slice(-1)[0]]

      if propType is 'Individual' and not typeIsArray loc
        throw new Error("Cannot use 'add' to set attribute. Use 'set' instead.")

      if propType is 'Value' and typeIsArray loc
        throw new Error("Cannot use 'set' to add relation. Use 'add' instead.")


    @set = (propPath, value)=>

      throw new Error("Value property/Attribute strings cannot contain the character '@'.") if value.indexOf('@') isnt -1
      throw new Error("Input argument strings cannot contain the character '$'.") if value.indexOf('$') isnt -1
      throw new Error(propPath + " is not a valid input argument for this model.") if not @inputArgs[propPath]

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

        throwIllegalCharacter = ->
          reject(new Error('This model instance has unset input arguments. All input arguments must be set before saving.'))


        if @inputArgs['rootId']
          root = new Weaver.Node(@inputArgs['rootId'])
        else
          root = new Weaver.Node()

        nodes.push(root)

        persistOneLevel = (parent, props)->

          for key,prop of props

            if typeIsObject prop

              child = new Weaver.Node()
              nodes.push(child)

              persistOneLevel(child, prop)
              parent.relation(key).add(child)

            else

              throwIllegalCharacter() if prop.indexOf('$') isnt -1

              parent.set(key, prop.slice(1)) if prop.indexOf('@') isnt -1

              if typeIsArray prop

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
          resolve(res)
        )

      )

module.exports = WeaverModel
