class WeaverRoot

  getClass: ->
    WeaverRoot
  @getClass: ->
    WeaverRoot

  @weaver: null

  @getWeaver: ->
    if not @weaver?
      throw new Error('Please set a reference to the Weaver instance first')
    @weaver

  @getWeaverClass: ->
    if not @weaver?
      throw new Error('Please set a reference to the Weaver instance first')
    @weaver.getClass()

  getWeaver: ->
    if not @getClass().weaver?
      throw new Error('Please set a reference to the Weaver instance first')
    @getClass().weaver

  getWeaverClass: ->
    if not @getClass().weaver?
      throw new Error('Please set a reference to the Weaver instance first')
    @getClass().weaver.getClass()


    
# Export
module.exports = WeaverRoot
