$ = require("./../test-suite")()
sinon   = require("sinon")
Promise = require("bluebird")
Entity = require('../../src/entity')
Weaver = require('../../src/weaver')

describe 'Entity: Fetching an entity', ->

  weaver   = new Weaver()
  weaver.connect('http://mockserver')
  channel  = null
  mockRead = null

  beforeEach ->
    weaver.repository.clear()
    channel = sinon.mock(weaver.channel)

    mockRead = (object) ->
      channel.expects('read').once().returns(Promise.resolve(object))

  afterEach ->
    channel.restore()


  it 'should correctly fetch circular references for a local entity', ->
    add = (type, data) ->
      data = {} if not data?
      entity = new Entity(data, type).$weaver(weaver)
      weaver.repository.add(entity)
      entity

    # Data
    dataset = add('dataset')
    dataset.objects = add('$COLLECTION')

    object = add('object')
    dataset.objects.$push(object)

    object.properties = add('$COLLECTION')
    property = add('property', {subject: object, predicate: 'hasName', value: 'Mohamad'})
    object.properties.$push(property)

    weaver.get(dataset.$id(), {eagerness: -1}).should.eventually.equal(dataset)


  it 'should correctly fetch circular references for a server entity', ->
    response =
      _META:
        id: '0'
        type: 'dataset'
        fetched: true
      objects:
        _META:
          id: '1'
          type: '$COLLECTION'
          fetched: true
        2:
          _META:
            id: '2'
            type: 'object'
            fetched: true
          properties:
            _META:
              id: '3'
              type: '$COLLECTION'
              fetched: true
            4:
              _META:
                id: '4'
                type: 'property'
                fetched: true
              predicate: 'hasName'
              value: 'Mohamad'
              subject:
                _REF: '2'

    mockRead(response)

    # Fetch first, then it is loaded in memory and try to get it again
    weaver.get('0', {eagerness: -1}).then((loaded) ->
      weaver.get('0', {eagerness: -1}).should.eventually.equal(loaded)
    )


  it 'should load nested object with empty repository', ->

      # Server responses
      fetchEagerness0 =
        _META:
          id: '0'
          type: 'user'
          fetched: false
        name: 'Mohamad Alamili'

      fetchEagerness1 =
        _META:
          id: '0'
          type: 'user'
          fetched: true
        name: 'Mohamad Alamili'
        friend:
          _META:
            id: '1'
            type: 'human'
            fetched: false
          name: 'Bastiaan Bijl'

      fetchEagerness2 =
        _META:
          id: '0'
          type: 'user'
          fetched: true
        name: 'Mohamad Alamili'
        friend:
          _META:
            id: '1'
            type: 'human'
            fetched: true
          name: 'Bastiaan Bijl'


      mockRead(fetchEagerness0)


      # Repo content
      friend = new Entity({name: 'Bastiaan Bijl'}, 'human', false, '1').$weaver(weaver)
      weaver.repository.add(friend)

      currentEntity = null
      # Load
      weaver.get('0', {eagerness: 0}).then((entity) ->
        # Assert returned value
        entity.$.fetched.should.be.false
        entity.$id().should.equal('0')
        expect(entity.friend).to.be.undefined

        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        currentEntity = entity
      ).then(->

        mockRead(fetchEagerness1)
        currentEntity.$fetch({eagerness: 1})

      )
      .then((entity) ->

        # Assert returned value
        entity.$.fetched.should.be.true
        entity.$id().should.equal('0')
        entity.friend.should.equal(friend)
        entity.friend.$.fetched.should.be.false

        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)

        currentEntity = entity
      ).then(->

        mockRead(fetchEagerness2)
        currentEntity.$fetch({eagerness: 2})

      ).then((entity) ->

        # Assert returned value
        entity.$.fetched.should.be.true
        entity.$id().should.equal('0')
        entity.friend.should.equal(friend)
        entity.friend.$.fetched.should.be.true

        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)

      )
