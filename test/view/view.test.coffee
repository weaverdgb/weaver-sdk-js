$ = require("./../test-suite")()

redis = new require('ioredis')()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect('http://localhost:9487')

mohamad = null

before('clear database', ->
  #redis.flushall()
)

beforeEach('clear repository', ->
  weaver.repository.clear()
)


describe 'Weaver: Creating entity', ->

  viewPromise = weaver.getView('cink2tywu000l3j6mdu6nf9y9')

  it 'should populate members', ->
    viewPromise.then((view) ->
      view.populate().then((members) ->
        console.log(members)
      )
    )
