Weaver = require('./Weaver')
util   = require('./util')
Chirql = require('chirql')

class ChirqlManager

  constructor: (language, namespaces)->

    @chirql = new Chirql(language, '', namespaces)

  query: (queryString)->
    tokenList = @chirql.lexer.lex(queryString)
    fragmentList = @chirql.parser.parseTokens(tokenList)
    query = @chirql.queryManager.transpile(fragmentList)
    new Weaver.Query().nativeQuery(query)

module.exports = ChirqlManager

