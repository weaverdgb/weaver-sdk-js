$ = require("./../test-suite")()
sinon   = require("sinon")
Promise = require("bluebird")
Entity = require('../../src/entity')
Weaver = require('../../src/weaver')

describe 'Entity: Fetching an entity', ->
  
  weaver   = new Weaver('http://mockserver')
  socket   = null
  mockRead = null
  
  beforeEach ->
    weaver.repository.clear()
    socket = sinon.mock(weaver.socket)

    mockRead = (object) ->
      socket.expects('read').once().returns(Promise.resolve(object))
     
  afterEach ->
    socket.restore()


      
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
      friend = new Entity({name: 'Bastiaan Bijl'}, 'human', false, '1').weaver(weaver)
      weaver.repository.add(friend)

      currentEntity = null
      # Load
      weaver.load('0', {eagerness: 0}).then((entity) ->
        # Assert returned value
        entity.$.fetched.should.be.false
        entity.id().should.equal('0')
        expect(entity.friend).to.be.undefined
        
        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        currentEntity = entity
      ).then(->

        mockRead(fetchEagerness1)
        currentEntity.fetch({eagerness: 1})
        
      )
      .then((entity) ->

        # Assert returned value
        entity.$.fetched.should.be.true
        entity.id().should.equal('0')
        entity.friend.should.equal(friend)
        entity.friend.$.fetched.should.be.false

        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)

        currentEntity = entity
      ).then(->
        
        mockRead(fetchEagerness2)
        currentEntity.fetch({eagerness: 2})

      ).then((entity) ->

        # Assert returned value
        entity.$.fetched.should.be.true
        entity.id().should.equal('0')
        entity.friend.should.equal(friend)
        entity.friend.$.fetched.should.be.true

        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)
        
      )
