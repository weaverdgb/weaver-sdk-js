$ = require("./../test-suite")()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect(WEAVER_ADDRESS)


describe 'Weaver: Dealing with entities', ->
  
  it 'should wipe the DB', ->
    
    weaver.wipe().then((res, err) ->
      if err
        console.log err
      else
        expect(res).equal('200')
    )
    
  it 'should wipe the weaver DB', ->
    
    weaver.wipeWeaver().then((res, err) ->
      if err
        console.log err
      else
        expect(res).equal('200')
    )
    
  it 'should creates an entity without attributes', ->
    
    weaver.node('toshio').then((res, err) =>
      if err
        console.log err
      else
        console.log res
        expect(res).to.have.property('id').and.equal('toshio')
        weaver.getNode(res).then((toshio, err) =>
          if err
            console.log err
          else
            console.log toshio
            expect(toshio).to.have.property('id').and.equal('toshio')
            expect(toshio).to.have.property('attributes').and.to.lengthOf(3)
            expect(toshio.attributes[0]).to.have.property('key').and.equal('$UA')
            expect(toshio.attributes[1]).to.have.property('key').and.equal('$CA')
            expect(toshio.attributes[2]).to.have.property('key').and.equal('LABEL')
        )
        
    )
    
  
  it 'should have all properties', ->
  
    weaver.node({name:'Gandalf the grey', age:334, id:'555h7', isMale:true},'Gandalf').then((gandalf, err) ->
      if err
        console.log err
      else
        console.log gandalf
        expect(gandalf).to.have.property('id').and.equal('Gandalf')
        expect(gandalf).to.have.property('attributes').and.to.lengthOf(3)
  
    )
  
  it 'should have all properties by reading after create', ->
  
    weaver.getNode('Gandalf').then((gandalf, err) ->
      if err
        console.log err
      else
        console.log gandalf
        expect(gandalf).to.have.property('id').and.equal('Gandalf')
        expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
        expect(gandalf).to.have.property('relations').and.to.lengthOf(0)
        expect(gandalf.attributes[0]).to.have.property('value').and.equal('Gandalf the grey')
        expect(gandalf.attributes[0]).to.have.property('key').and.equal('name')
        expect(gandalf.attributes[2]).to.have.property('value').and.equal(true)
        expect(gandalf.attributes[2]).to.have.property('key').and.equal('isMale')
        expect(gandalf.attributes[4]).to.have.property('id').and.equal('555h7')
        expect(gandalf.attributes[4]).to.have.property('value').and.equal('334.0@555h7')
        expect(gandalf.attributes[4]).to.have.property('key').and.equal('age')
        expect(gandalf.attributes[5]).to.have.property('key').and.equal('LABEL')
        expect(gandalf.attributes[5]).to.have.property('value').and.equal('INDIVIDUAL')
    )
  
  it 'should update an entity', ->
  
    weaver.update({name:'Gandalf the white',age:555,id:'555h5'},'Gandalf').then((gandalf, err) =>
      if err
        console.log err
      else
        console.log gandalf
        expect(gandalf).to.have.property('id').and.equal('Gandalf')
        expect(gandalf).to.have.property('attributes').and.to.lengthOf(2)
        expect(gandalf.attributes[0]).to.have.property('value').and.equal('Gandalf the white')
        expect(gandalf.attributes[0]).to.have.property('key').and.equal('name')
        expect(gandalf.attributes[1]).to.have.property('id').and.equal('555h5')
        expect(gandalf.attributes[1]).to.have.property('value').and.equal(555)
        expect(gandalf.attributes[1]).to.have.property('key').and.equal('age')
    )
  
  it 'should read an updated entity', ->
  
    weaver.getNode('Gandalf').then((gandalf, err) ->
      if err
        console.log err
      else
        console.log gandalf
        expect(gandalf).to.have.property('id').and.equal('Gandalf')
        expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
        expect(gandalf).to.have.property('relations').and.to.lengthOf(0)
        expect(gandalf.attributes[0]).to.have.property('value').and.equal('Gandalf the white')
        expect(gandalf.attributes[0]).to.have.property('key').and.equal('name')
        expect(gandalf.attributes[2]).to.have.property('value').and.equal(true)
        expect(gandalf.attributes[2]).to.have.property('key').and.equal('isMale')
        expect(gandalf.attributes[4]).to.have.property('id').and.equal('555h5')
        expect(gandalf.attributes[4]).to.have.property('value').and.equal('555.0@555h5')
        expect(gandalf.attributes[4]).to.have.property('key').and.equal('age')
        expect(gandalf.attributes[5]).to.have.property('key').and.equal('LABEL')
        expect(gandalf.attributes[5]).to.have.property('value').and.equal('INDIVIDUAL')
    )
  
  it 'should creates a link entity from the returned object', ->
  
    weaver.node({name:'Sauron the dark wizzard', age:'before the ring',isEvil:true},'Sauron').then((sauron, err) ->
      if err
        console.log err
      else
        console.log sauron
        expect(sauron).to.have.property('id').and.equal('Sauron')
        weaver.link(sauron,{isEnemy:'Gandalf'})
    )
  
  it 'should creates a link from the id to the returned object, without id, and then read it', ->
  
    weaver.node({name:'Captain Orc', age:'unknown'}).then((res, err) =>
      if err
        console.log err
      else
        weaver.link('Gandalf',{fights:res}).then((res, err) =>
          if err
            console.log err
          else
            weaver.getNode('Gandalf').then((gandalf, err) =>
              if err
                console.log err
              else
                expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
                expect(gandalf).to.have.property('relations').and.to.lengthOf(1)
                expect(gandalf.relations[0]).to.have.property('relation').and.equal('fights')
                expect(gandalf.relations[0]).to.have.property('target')
                expect(gandalf.relations[0].target).to.have.property('id')
                expect(gandalf.relations[0].target).to.have.property('attributes').and.to.lengthOf(5)
                expect(gandalf.relations[0].target.attributes[0]).to.have.property('key').and.equal('name')
                expect(gandalf.relations[0].target.attributes[0]).to.have.property('value').and.equal('Captain Orc')
            )
        )
    )
  
  it 'should creates an entity without an id and update with the result at the end, and then read it', ->
  
    weaver.node({name:'Black rider', isEvil:true}).then((entity, err) =>
      if err
        console.log err
      else
        console.log entity
        expect(entity).to.have.property('attributes').and.to.lengthOf(2)
        expect(entity.attributes[0]).to.have.property('key').and.equal('name')
        expect(entity.attributes[0]).to.have.property('value').and.equal('Black rider')
        expect(entity.attributes[1]).to.have.property('key').and.equal('isEvil')
        expect(entity.attributes[1]).to.have.property('value').and.equal(true)
        weaver.update({name:'The human king black rider', age:2050},entity).then((res, err) =>
          if err
            console.log err
          else
            weaver.getNode(entity).then((res, err) =>
              if err
                console.log err
              else
                expect(res).to.have.property('attributes').and.to.lengthOf(6)
                expect(res.attributes[0]).to.have.property('key').and.equal('name')
                expect(res.attributes[0]).to.have.property('value').and.equal('The human king black rider')
                expect(res.attributes[4]).to.have.property('key').and.equal('age')
                expect(res.attributes[4]).to.have.property('value').and.equal(2050)
            )
        )
    )
  
  it 'should creates an entity on the linking',  ->
    weaver.link('Gandalf',{isFriend:'Bilbo'}).then((res, err) =>
      if err
        console.log err
      else
        # console.log res
        weaver.getNode('Gandalf').then((gandalf, err) =>
          if err
           console.log err
          else
            expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
            expect(gandalf).to.have.property('relations').and.to.lengthOf(2)
            expect(gandalf.relations[0]).to.have.property('relation').and.equal('fights')
            expect(gandalf.relations[1]).to.have.property('relation').and.equal('isFriend')
            expect(gandalf.relations[0]).to.have.property('target')
            expect(gandalf.relations[0].target).to.have.property('id')
            expect(gandalf.relations[0].target).to.have.property('attributes').and.to.lengthOf(5)
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('key').and.equal('name')
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('value').and.equal('Captain Orc')
            weaver.getNode('Bilbo').then((bilbo, err) =>
               if err
                err
               else
                 console.log bilbo
                 expect(bilbo).to.have.property('id').and.equal('Bilbo')
                 expect(bilbo).to.have.property('attributes').and.to.lengthOf(1)
                 expect(bilbo.attributes[0]).to.have.property('key').and.equal('LABEL')
                 expect(bilbo.attributes[0]).to.have.property('value').and.equal('INDIVIDUAL')
            )
  
        )
    )
    
  it 'should creates a relationships with an Array', ->
    
    weaver.link('Gandalf',{isFriend:['Sam','Aragorn'], isEnemy:'Saruman'}).then((res, err) =>
      if err
        console.log err
      else
        console.log res
        weaver.getNode('Gandalf').then((gandalf, err) =>
          if err
           console.log err
          else
            console.log gandalf
            console.log gandalf.relations[3].target
            expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
            expect(gandalf).to.have.property('relations').and.to.lengthOf(5)
            # expect(gandalf.relations[0]).to.have.property('relation').and.equal('fights')
            # expect(gandalf.relations[1]).to.have.property('relation').and.equal('isEnemy')
            # expect(gandalf.relations[2]).to.have.property('relation').and.equal('isFriend')
            # expect(gandalf.relations[3]).to.have.property('relation').and.equal('isFriend')
            # expect(gandalf.relations[4]).to.have.property('relation').and.equal('isFriend')
            expect(gandalf.relations[0]).to.have.property('target')
            expect(gandalf.relations[0].target).to.have.property('id')
            expect(gandalf.relations[0].target).to.have.property('attributes').and.to.lengthOf(5)
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('key').and.equal('name')
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('value').and.equal('Captain Orc')
      )
    )
    
  # it 'should unlink a couple of relationships', ->
  #
  #   weaver.unlink('Gandalf',{isEnemy:'Saruman'}).then((res, err) =>
  #     if err
  #       console.log err
  #     else
  #       console.log res
  #   )
  #
    
    
  # it 'should starts the bulk importer', (done) ->
  #   weaver.startBulk()
  #   done()
    
        
  it 'should disconnect', ->
    
    weaver.disconnect()