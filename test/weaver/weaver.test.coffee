$ = require("./../test-suite")()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect(WEAVER_ADDRESS)

# describe 'Authentication', ->
#   after: ->
#     weaver.channel.emit.restore()

  # it 'should send a token', ->
  #   sinon.stub(weaver.channel, "emit");
  #   weaver.channel.emit.returns(Promise.resolve({ read: true, write: false}))
  #
  #   promise = weaver.authenticate('test123')
  #   expect(weaver.channel.emit.callCount).to.equal(1)
  #   expect(weaver.channel.emit.firstCall.args[0]).to.equal('authenticate')
  #   expect(weaver.channel.emit.firstCall.args[1]).to.equal('test123')
  #   promise.should.eventually.eql({ read: true, write: false })

describe 'Weaver: Creating entity', ->
  
  console.log WEAVER_ADDRESS
  
  it 'should have all properties', ->
    sinon.stub(weaver.channel, "emit")
    # promise = weaver.node({name:'Gandalf the white', age:534, id:'555h7', isMale:true},'Gandalf')
    # console.log promise
    # promise.should.eventually.eql(['200'])
    # weaver.channel.emit.returns(Promise.resolve({ read: true, write: false}))
    weaver.node({name:'Gandalf the white', age:534, id:'555h7', isMale:true},'Gandalf').then((res) =>
      console.log '=^^=|_'
      console.log res
    )
    
  
  
  # gandalf = {}
  #
  # weaver.node({name:'Gandalf the white', age:534, id:'555h5', isMale:true},'Gandalf').then((res, err) =>
  #   console.log res
  #   gandalf = res
  #   it 'should have all properties', ->
  #     gandalf.should.have('name')
  # )
  
  
  # it 'should have all properties', ->
  #   gandalf.should.have('name')