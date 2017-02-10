Weaver      = require('./Weaver')
Chirql      = require('chirql')


class WeaverModelQuery extends Weaver.Query

  constructor: ()->

    @chirql = new Chirql('SPARQL', false, [{prefix:'wv:', namespace:'http://weav.er#'}])

  query: (queryString)->

    tokenList     = @chirql.lexer.lex(queryString)
    fragmentList  = @chirql.parser.parseTokens(tokenList)
    outgoingQuery = @chirql.queryManager.transpile(fragmentList)

    queryObj = new Weaver.Query()

    queryObj.nativeQuery(outgoingQuery).then((res)->
      console.log(res)
    )


module.exports = WeaverModelQuery
