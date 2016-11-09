$ = require("./../test-suite")()

# Weaver
Weaver = require('./../../src/weaver')
weaver = new Weaver()
weaver.connect(WEAVER_ADDRESS)


describe 'Weaver: Dealing with entities', ->
  # Increasing the timeout, due to debugging purposes (the logger.debug on the weaver-neo4j-service is to much intense)
  @timeout(70000)
  
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
            expect(gandalf).to.have.property('attributes').and.to.lengthOf(6)
            expect(gandalf).to.have.property('relations').and.to.lengthOf(5)
            # TODO: How to deal with different order into the Array of relations?
            # expect(gandalf.relations[0]).to.have.property('relation').and.equal('fights')
            # expect(gandalf.relations[1]).to.have.property('relation').and.equal('isEnemy')
            # expect(gandalf.relations[2]).to.have.property('relation').and.equal('isFriend')
            # expect(gandalf.relations[3]).to.have.property('relation').and.equal('isFriend')
            # expect(gandalf.relations[4]).to.have.property('relation').and.equal('isFriend')
            # expect(gandalf.relations).to.include.property('[0][1][2][3].relation',)
            expect(gandalf.relations[0]).to.have.property('target')
            expect(gandalf.relations[0].target).to.have.property('id')
            expect(gandalf.relations[0].target).to.have.property('attributes').and.to.lengthOf(5)
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('key').and.equal('name')
            expect(gandalf.relations[0].target.attributes[0]).to.have.property('value').and.equal('Captain Orc')
      )
    )
    
  it 'should remove an entity', ->
    
    weaver.getNode('Bilbo').then((bilbo, err) =>
      if err
        console.log err
      else
        console.log bilbo
        expect(bilbo).to.have.property('id').and.equal('Bilbo')
        weaver.destroy(bilbo).then((res, err) =>
          if err
            console.log err
          else
            console.log res
            weaver.getNode('Bilbo').then((resp, err) =>
              console.log resp
              expect(resp).equal('The entity does not exits')
            )
        )
    )
    
  it 'should unlink a couple of relationships', ->
  
    weaver.unlink('Gandalf',{isEnemy:'Saruman',isFriend:['Aragorn','Sam']}).then((res, err) =>
      if err
        console.log err
      else
        console.log res
        weaver.getNode('Gandalf').then((gandalf, err) ->
          console.log gandalf
          expect(gandalf).to.have.property('relations').and.to.lengthOf(1)
        )
        
    )
    
  it 'should create some relations', ->
    
    weaver.link('toshio',{isFriend:['samantha','jason','meyers'],isEnemy:'tokyoPoliceOfficer'}).then((res, err) ->
      console.log res
      weaver.getNode('toshio').then((toshio, err) ->
        console.log toshio
        expect(toshio).to.have.property('relations').and.to.lengthOf(4)
        weaver.link('tokyoPoliceOfficer',{isFriend:'tokyoJournalist'}).then((resp, err) ->
          console.log resp
          weaver.getNode('tokyoPoliceOfficer').then((police, err) ->
            console.log  police
            expect(police).to.have.property('relations').and.to.lengthOf(1)
            expect(police.relations[0]).to.have.property('relation').and.equal('isFriend')
            expect(police.relations[0]).to.have.property('target')
            expect(police.relations[0].target).to.have.property('id').and.equal('tokyoJournalist')
            weaver.link('tokyoJournalist',{isFriend:'foreignerSocialWorker'}).then((res, err) ->
              weaver.getNode('tokyoJournalist').then((tokyoJournalist, err) ->
                console.log  tokyoJournalist
                expect(tokyoJournalist).to.have.property('relations').and.to.lengthOf(1)
                weaver.link('foreignerSocialWorker',{isKilledBy:'toshio',attendingTo:'grandmothersToshio'}).then((res, err) ->
                  if not err
                    weaver.getNode('foreignerSocialWorker').then((foreignerSocialWorker, err) ->
                      console.log(JSON.stringify(foreignerSocialWorker))
                      expect(foreignerSocialWorker).to.have.property('relations').and.to.lengthOf(2)
                    )
                )
              )
            )
          )
        )
      )
    )
    
  it 'should read eagernes 1 (the default) from entity', ->
    
    weaver.getNode('toshio').then((toshio, err) ->
      console.log(JSON.stringify(toshio))
      expect(toshio.relations).to.include({relation:'isEnemy',target:{id:'tokyoPoliceOfficer',attributes:[ { value: 'INDIVIDUAL', key: 'LABEL' }],relations: [],relationsReferences:[]}})
    )
    
    
  it 'should read eagernes 2 from entity', (done) ->
    
    weaver.getNode('toshio',{eagerness:2}).then((toshio, err) ->
      if toshio
        console.log(JSON.stringify(toshio))
        for relation in toshio.relations
          console.log(JSON.stringify(relation))
          if relation.target.relations.length is 1
            done()
    )
    
    
  it 'should read eagernes 3 from entity', (done) ->
    
    weaver.getNode('toshio',{eagerness:3}).then((toshio, err) ->
      if toshio
        console.log(JSON.stringify(toshio))
        for relation in toshio.relations
          console.log(JSON.stringify(relation))
          if relation.target.relations.length is 1
            if relation.target.relations[0].target.relations.length is 1
              done()
    )
    
  it 'should read eagernes 4 from entity', (done) ->
    
    weaver.getNode('toshio',{eagerness:4}).then((toshio, err) ->
      if toshio
        console.log(JSON.stringify(toshio))
        for relation in toshio.relations
          console.log(JSON.stringify(relation))
          if relation.target.relations.length is 1
            if relation.target.relations[0].target.relations.length is 1
              if relation.target.relations[0].target.relations[0].target.relations.length is 1
                done()
    )
  
  it 'should read eagernes 4 from entity and check for the relationsReferences to the same entity', (done) ->
    
    weaver.getNode('toshio',{eagerness:4}).then((toshio, err) ->
      if toshio
        console.log(JSON.stringify(toshio))
        for relation in toshio.relations
          console.log(JSON.stringify(relation))
          if relation.target.relations.length is 1
            if relation.target.relations[0].target.relations.length is 1
              if relation.target.relations[0].target.relations[0].target.relationsReferences.length is 1
                done()
    )
    
  it 'should create 1000 entities with the bulk operation for nodes', (done) ->
    
    bulk = {}
    nodesArray = []
    
    for i in [0..1000]
      weaverEntity = {}
      attribute = {}
      arr = []
      weaverEntity.id = i
      attribute.key = 'LABEL'
      attribute.value = if i % 2 is 0 then 'EVEN' else 'ODD'
      arr.push attribute
      attribute = {}
      attribute.key = 'Description'
      attribute.value = Math.random().toString(36).substring(7)
      arr.push attribute
      attribute = {}
      attribute.key = 'Name'
      attribute.value = parseInt(i)
      arr.push attribute
      weaverEntity.attributes = arr
      nodesArray.push(weaverEntity)
    bulk.bulk = nodesArray
    
    weaver.bulkNodes(bulk).then((res, err) ->
      console.log res
      weaver.getNode('1').then((res, err) ->
        console.log res
        expect(res).to.have.property('id').and.equal('1')
        done()
      )
    )
    
  it 'should create 1000 relationships with the bulk operation for relationships', (done) ->
    
    bulk = {}
    relationsArray = []
    number_of_nodes = 1000
    
    for i in [0..number_of_nodes]
      weaverEntity = {}
      relation = {}
      arr = []
      weaverEntity.id = i
      # rel = Math.floor((Math.random() * number_of_nodes) + 1)
      rel = i+1
      relation.relation = 'relation'.concat(rel)
      if i is number_of_nodes
        relation.target = 0
      else
        relation.target = rel
      arr.push relation
      weaverEntity.relations = arr
      relationsArray.push(weaverEntity)
    bulk.bulk = relationsArray
    
    weaver.bulkRelations(bulk).then((res, err) ->
      console.log res
      # done()
      weaver.getNode('1').then((res, err) ->
        console.log res
        expect(res).to.have.property('id').and.equal('1')
        expect(res.relations[0]).to.have.property('relation').and.equal('relation2')
        done()
      )
    )
    
    
    
    
  it 'should disconnect', ->
    
    weaver.disconnect()