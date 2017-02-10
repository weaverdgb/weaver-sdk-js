require("./test-suite")

describe 'WeaverModelQuery', ->

  it 'should make a query which returns all requirement model members', ->

    typeQuery = new Weaver.ModelQuery()

    queryString = """{
      wv:hasType
    }"""

    typeQuery.query(queryString).then((res)->
      console.log(res)
    )
