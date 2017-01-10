# Libs
chirql     = require('chirql')
cuid       = require('cuid')
Weaver     = require('./Weaver')

module.exports =
  class WeaverQueryHandler

    constructor: (@namespaces, language) ->
      @nodeId = cuid()      # Generate random id
      @attributes = {}      # Store all attributes in this object

      #this can be replaced as soon as native-query functionality is in place
      @chirql = new chirql(language, 'http://localhost:8890/sparql', @namespaces)


    add: ->

    remove: ->

    runQuery: (queryString)->

      new Promise((resolve, reject)=>
        @chirql.runQuery(queryString).then((res, rej)->
          reject(rej) if rej
          resolve(res) if res
        )
      )


# Export
Weaver.QueryHandler   = WeaverQueryHandler
module.exports = WeaverQueryHandler
