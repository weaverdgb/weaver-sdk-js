$ = require("./../test-suite")()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect(WEAVER_ADDRESS)


describe 'Weaver: Dealing with Dict (Redis)', ->
  
  it 'should create a dict', ->
    
    weaver.dict({pss:'kjnb564hasduyu', usr:'gandalefa'},'gandalfUser').then((gandalf, err) ->
      if err
        console.log err
      else
        console.log gandalf
        expect(gandalf[0]).equal('OK')
    )
    
  it 'should read after dict create', ->
    
    weaver.getDict('gandalfUser').then((gandalf, err) ->
      if err
        console.log err
      else
        expect(gandalf[0]).to.have.property('id').and.equal('gandalfUser')
        expect(gandalf[0]).to.have.property('data').and.to.lengthOf(2)
        expect(gandalf[0].data).to.have.lengthOf(2)
        expect(gandalf[0].data[0]).to.have.property('key').and.equal('pss')
        expect(gandalf[0].data[0]).to.have.property('value').and.equal('kjnb564hasduyu')
        expect(gandalf[0].data[1]).to.have.property('key').and.equal('usr')
        expect(gandalf[0].data[1]).to.have.property('value').and.equal('gandalefa')
        
    )