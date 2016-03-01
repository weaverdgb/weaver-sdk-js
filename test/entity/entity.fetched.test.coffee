$ = require("./../test-suite")()
Entity = require('../../src/entity')

describe 'Entity: Testing if an entity is fetched', ->

  construct = (fetched) ->
    new Entity({}, null, fetched)

  it 'should always be true for eagerness 0', ->
    a = construct(false)
    a.isFetched(0).should.be.true

    a = construct(true)
    a.isFetched(0).should.be.true


  it 'should be true for eagerness 1', ->
    a = construct(true)
    
    a.isFetched(1).should.be.true
    
    
  it 'should be false for eagerness 1', ->
    a = construct(false)
    
    a.isFetched(1).should.be.false
    
    
  it 'should be true for eagerness 2 while not having links', ->
    a = construct(true)
    a.isFetched(2).should.be.true    
    
    
  it 'should be false for eagerness 1 while having links', ->
    a = construct(true)
    b = construct(false)
    a.link = b
    
    a.isFetched(1).should.be.true 
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(false)
    a.link = b

    a.isFetched(2).should.be.false    
    
    
  it 'should be false for eagerness -1 while having links', ->
    a = construct(true)
    b = construct(false)
    a.link = b

    a.isFetched(-1).should.be.false    
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(false)
    c = construct(false)
    
    a.link = b
    b.link = c
    c.link = a
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.false
    a.isFetched(3).should.be.false
    a.isFetched(-1).should.be.false    
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(true)
    c = construct(false)
    
    a.link = b
    b.link = c
    c.link = a
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.true
    a.isFetched(3).should.be.false
    a.isFetched(-1).should.be.false    
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(true)
    c = construct(false)
    
    a.link = b
    a.link = c
    c.link = a
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.false
    a.isFetched(3).should.be.false
    a.isFetched(-1).should.be.false    
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(true)
    c = construct(false)
    
    a.link = b
    a.link = c
    c.link = a
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.false
    a.isFetched(3).should.be.false
    a.isFetched(-1).should.be.false    
    
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(true)
    c = construct(true)
    d = construct(true)
    e = construct(true)
    x = construct(true)
    y = construct(false)

    a.link1 = b
    a.link2 = c
    c.link = d
    d.link = e
    e.link = x
    b.link = x
    x.link = y
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.true
    a.isFetched(3).should.be.true
    a.isFetched(4).should.be.false
    a.isFetched(5).should.be.false
    a.isFetched(6).should.be.false
    a.isFetched(-1).should.be.false
       
    
    
  it 'should be false for eagerness 2 while having links', ->
    a = construct(true)
    b = construct(true)
    c = construct(true)
    d = construct(true)
    e = construct(true)
    x = construct(true)
    y = construct(false)

    a.link1 = c
    a.link2 = b
    c.link = d
    d.link = e
    e.link = x
    b.link = x
    x.link = y
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.true
    a.isFetched(3).should.be.true
    a.isFetched(4).should.be.false
    a.isFetched(5).should.be.false
    a.isFetched(6).should.be.false
    a.isFetched(-1).should.be.false
   
  it 'do complicated stuff', ->
    a = construct(true)
    b = construct(true)
    c = construct(true)
    d = construct(true)
    e = construct(true)
    x = construct(true)
    y = construct(false)

    a.link1 = c
    a.link2 = b
    c.link = d
    d.link = e
    e.link = x
    b.link = x
    x.link = y
    x.linke = a
    
    a.isFetched(0).should.be.true
    a.isFetched(1).should.be.true
    a.isFetched(2).should.be.true
    a.isFetched(3).should.be.true
    a.isFetched(4).should.be.false
    a.isFetched(5).should.be.false
    a.isFetched(6).should.be.false
    a.isFetched(-1).should.be.false