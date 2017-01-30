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
        fragments = arr.slice(1,arr.length-1)

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

                return(new Error('Value property/Attribute strings cannot contain \'@\'')) if fragment.object.indexOf('@') isnt -1

                if fragment.type is 'Individual'
                  returnObj[fragment.predicate] = fragment.object
                else
                  returnObj[fragment.predicate] = '@' + fragment.object

              else
                returnObj[fragment.predicate] = 'RANDOM' if fragment.type is 'Individual'

                returnObj[fragment.predicate] = '@EMPTY' if fragment.type is 'Value'
        returnObj

      definition = parseOneLevel(fragmentList, [])

      @definition = definition

class ModelInstance

  constructor: (modelDefinition, @inputArgs)->
    @instance = {}
    @instance[i] = j for i, j of modelDefinition when i isnt 'inputArgs'

    typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'
    typeIsObject = Object.isObject || ( value ) -> return {}.toString.call( value ) is '[object Object]'


    @set = (propPath, value)=>

      return(new Error('Value property/Attribute strings cannot contain \'@\'')) if value.indexOf('@') isnt -1

      path = @inputArgs[propPath]

      pointer = @instance
      pointer = pointer[p] for p in path.slice(0, -1)
      pointer[path.slice(-1)[0]] = '@' + value


    @add = (propPath, value)=>

      path = @inputArgs[propPath]

      pointer = @instance
      pointer = pointer[p] for p in path.slice(0, -1)
      ref = pointer[path.slice(-1)[0]]

      if not typeIsArray ref

        pointer[path.slice(-1)[0]] = [ref]

      pointer[path.slice(-1)[0]].push(value)

    @save = ->

      nodes = []
      new Promise((resolve,reject)=>
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
              parent.set(key, prop.slice(1)) if prop.indexOf('@') isnt -1

              if prop.indexOf('@') is -1
                indiProp = new Weaver.Node()
                nodes.push(indiProp)

                parent.relation(key).add(indiProp)

        persistOneLevel(root, @instance)

        promises = []
        promises.push(node.save()) for node in nodes

        Promise.all(promises).then((res)->

          resolve(res)

        )

      )

module.exports = WeaverModel
