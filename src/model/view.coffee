Promise = require('bluebird')

module.exports =
class View



  constructor: (@entity) ->
    @members = {}
    @weaver = @entity.$.weaver
    if @entity.$type() isnt '$VIEW'
      throw new Error('entity should be $VIEW')

  retrieved: (id) ->
    @members[id]?


  populate: ->

    console.log('read view from db with id'+@entity.$id())
    @weaver.channel.queryFromView({id: @entity.$id()}).bind(@).then((memberIds) ->

      promises = []

      if not memberIds? or typeof memberIds isnt 'object' # actually array      
        console.error('the populate from view did not return an array result')
        return @members
      
      # if no results
      if not memberIds[0]?
        return @members
        
      memberIds.forEach((memberId) =>
        if not @retrieved(memberId)
          promises.push(@weaver.get(memberId, {eagerness : 1}).bind(@).then((entity) ->
            @members[memberId] = entity
          ))
      )

      Promise.all(promises).bind(@).then(->
        return @members
      )
    )


  populateFromFilters: (filters) ->

    filtersJson = JSON.stringify(filters)

    console.log('read view from db with id'+@entity.$id())
    @weaver.channel.queryFromFilters(filtersJson).bind(@).then((memberIds) ->

      promises = []

      if not memberIds? or typeof memberIds isnt 'object' # actually array      
        console.error('the populate from view did not return an array result')
        return @members
        

      memberIds.forEach((memberId) =>
        if not @retrieved(memberId)
          promises.push(@weaver.get(memberId, {eagerness : 1}).bind(@).then((entity) ->
            @members[memberId] = entity
          ))
      )

      Promise.all(promises).bind(@).then(->
        return @members
      )
    )


