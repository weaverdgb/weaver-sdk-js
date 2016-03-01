$ = require("./test-suite")()
sinon   = require("sinon")
Promise = require("bluebird")

Entity = require('../src/entity')
Weaver = require('../src/weaver')

describe 'Loading an entity', ->
  
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
      return            

      # Server response
      object = 
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
          
      mockRead(object)

      # Load
      weaver.load('0').then((entity) ->
        # Assert returned value
        entity.$.fetched.should.be.true
        entity.name.should.equal('Mohamad Alamili')
        entity.friend.id().should.equal('1')
        
        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)
      )



      
  it 'should load nested object with non empty repository', ->
      return
      # Server response
      object = 
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
          
      mockRead(object)
          
      # Repository
      repoEntity = new Entity({existing: true}, 'user', false, '0')
      weaver.repository.add(repoEntity)
      
      # Load
      weaver.load('0').then((entity) ->
                
        # Assert returned value
        entity.should.equal(repoEntity)
        entity.$.fetched.should.be.true
        entity.existing.should.be.true
        entity.friend.id().should.equal('1')

        # Name is not transferred
        expect(entity.name).to.be.undefined
        
        # Assert repository content
        weaver.repository.size().should.equal(2)
        weaver.repository.get('0').should.equal(entity)
        weaver.repository.get('1').should.equal(entity.friend)
      )


  it 'should load nested object with mixed repository', ->
    # Server response
    object =
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
      computer:
        _META:
          id: '2'
          type: 'thing'
          fetched: true
        name: 'Dead Silent Blazing Fast'
        processor:
          _META:
            id: '3'
            type: 'thing'
            fetched: true
          name: 'Intel CPU'
          fan:
            _META:
              id: '4'
              type: 'thing'
              fetched: false
            name: '5V low speed'
            

    mockRead(object)

    # Repository
    cpuEntity = new Entity({existing: true}, 'thing', false, '3')
    weaver.repository.add(cpuEntity)

    # Load
    weaver.load('0').then((entity) ->

      # Assert returned value
      entity.computer.processor.should.equal(cpuEntity)
      entity.computer.processor.fan.id().should.equal('4')

      # Assert repository content
      weaver.repository.size().should.equal(5)
      weaver.repository.get('0').should.equal(entity)
      weaver.repository.get('1').should.equal(entity.friend)
      weaver.repository.get('2').should.equal(entity.computer)
      weaver.repository.get('3').should.equal(entity.computer.processor)
      weaver.repository.get('3').should.equal(cpuEntity)
      weaver.repository.get('4').should.equal(cpuEntity.fan)
      weaver.repository.get('4').should.equal(entity.computer.processor.fan)
    )




  it 'should load nested object with mixed repository case extreme', ->
  # Server:     (A)+ -> (B)+ -> (C)+ -> (D)+ -> (E)-
  # Repository: (X)+ -> (C)-
    
  # Server response
    object =
      _META:
        id: '0'
        type: 'user'
        fetched: true
      name: 'Mohamad Alamili'
      computer:
        _META:
          id: '1'
          type: 'thing'
          fetched: true
        name: 'Dead Silent Blazing Fast'
        processor:
          _META:
            id: '2'
            type: 'thing'
            fetched: true
          name: 'Intel CPU'
          fan:
            _META:
              id: '3'
              type: 'thing'
              fetched: true
            name: '5V low speed'
            motor:
              _META:
                id: '4'
                type: 'thing'
                fetched: false
                name: 'DC Brushless'


    mockRead(object)

    # Repository
    manufacturer = new Entity({name: 'Intel Corp'}, 'company', true, '666')
    weaver.repository.add(manufacturer)

    processor    = new Entity({existing: true, manufactured: 'israel'}, 'thing', false, '2')
    weaver.repository.add(processor)
    
    manufacturer.produces = processor

    # Load
    weaver.load('0').then((entity) ->

      # Assert returned value
      entity.computer.processor.should.equal(processor)
      entity.computer.processor.fan.id().should.equal('3')

      # Assert repository content
      weaver.repository.size().should.equal(6)
      weaver.repository.get('0').should.equal(entity)
      weaver.repository.get('1').should.equal(entity.computer)
      weaver.repository.get('2').should.equal(entity.computer.processor)
      weaver.repository.get('2').should.equal(processor)
      weaver.repository.get('3').should.equal(processor.fan)
      weaver.repository.get('4').should.equal(processor.fan.motor)
      weaver.repository.get('4').should.equal(entity.computer.processor.fan.motor)
      weaver.repository.get('4').should.equal(manufacturer.produces.fan.motor)
      weaver.repository.get('666').should.equal(manufacturer)
    )
    




  it 'should load nested object with mixed repository case extreme 2', ->
  # Server:     (A)+ -> (B)+ -> (C)+ -> (D)-
  # Repository: (C)+ -> (D)+ -> (F)-
  #                  -> (E)+
    
  # Server response
    object =
      _META:
        id: '0'
        type: 'object'
        fetched: true
      name: 'A'
      link:
        _META:
          id: '1'
          type: 'object'
          fetched: true
        name: 'B'
        link:
          _META:
            id: '2'
            type: 'object'
            fetched: true
          name: 'C'
          link:
            _META:
              id: '3'
              type: 'object'
              fetched: false
            name: 'D'

    mockRead(object)

    # Repository
    C = new Entity({name: 'C'}, 'object', true, '2')
    weaver.repository.add(C)

    D = new Entity({name: 'D'}, 'object', true, '3')
    weaver.repository.add(D)

    E = new Entity({name: 'E'}, 'object', true, '4')
    weaver.repository.add(E)
  
    F = new Entity({name: 'F'}, 'object', false, '5')
    weaver.repository.add(F)

    # Links
    C.link  = D
    C.link2 = E
    D.link  = F

    # Load
    weaver.load('0').then((entity) ->

      # Assert returned value
      entity.link.link.should.equal(C)
      entity.link.link.link.should.equal(D)
      entity.link.link.link2.should.equal(E)
      entity.link.link.link.link.should.equal(F)

      # Assert repository content
      weaver.repository.size().should.equal(6)
      weaver.repository.get('0').should.equal(entity)
      weaver.repository.get('1').should.equal(entity.link)
      weaver.repository.get('2').should.equal(entity.link.link)
      weaver.repository.get('2').should.equal(C)
      weaver.repository.get('3').should.equal(entity.link.link.link)
      weaver.repository.get('3').should.equal(C.link)
      weaver.repository.get('4').should.equal(C.link2)
      weaver.repository.get('4').should.equal(entity.link.link.link2)
      weaver.repository.get('5').should.equal(entity.link.link.link.link)
      weaver.repository.get('5').should.equal(C.link.link)
    )  
    
  it 'should load circular refs', ->
  # Server:     (A)+ -> (B)+ -> (C)+ -> (D)-
  # Repository: (C)+ -> (D)+ -> (F)-
  #                  -> (E)+
    
  # Server response
    object =
      _META:
        id: '0'
        type: 'object'
        fetched: true
      name: 'A'
      link:
        _META:
          id: '1'
          type: 'object'
          fetched: true
        name: 'B'
        link:
          _META:
            id: '2'
            type: 'object'
            fetched: true
          name: 'C'
          link:
            _REF: '0'

    mockRead(object)

    # Load
    weaver.load('0', {eagerness: -1}).then((entity) ->

      # Assert repository content
      weaver.repository.size().should.equal(3)
      weaver.repository.get('0').name.should.equal('A')
      weaver.repository.get('1').name.should.equal('B')
      weaver.repository.get('2').name.should.equal('C')
      weaver.repository.get('0').should.equal(weaver.repository.get('2').link) 
    )

    
  it 'should not load from server if available in repository', ->
    
    # Server response
    socket.expects('read').never()

    # Repository
    C = new Entity({name: 'C'}, 'object', true, '2')
    weaver.repository.add(C)

    D = new Entity({name: 'D'}, 'object', true, '3')
    weaver.repository.add(D)

    E = new Entity({name: 'E'}, 'object', true, '4')
    weaver.repository.add(E)
  
    F = new Entity({name: 'F'}, 'object', false, '5')
    weaver.repository.add(F)

    # Links
    C.link  = D
    C.link2 = E
    D.link  = F

    # Load
    weaver.load('2').then((entity) ->

      # Assert returned value
      entity.should.equal(C)
      entity.link.should.equal(D)
      entity.link2.should.equal(E)
      entity.link.link.should.equal(F)

      # Assert repository content
      weaver.repository.size().should.equal(4)
      weaver.repository.get('2').should.equal(entity)
      weaver.repository.get('2').should.equal(C)
      weaver.repository.get('3').should.equal(entity.link)
      weaver.repository.get('3').should.equal(C.link)
      weaver.repository.get('4').should.equal(C.link2)
      weaver.repository.get('4').should.equal(entity.link2)
      weaver.repository.get('5').should.equal(entity.link.link)
      weaver.repository.get('5').should.equal(C.link.link)
    )
    





