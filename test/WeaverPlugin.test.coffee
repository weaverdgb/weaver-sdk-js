weaver = require("./test-suite").weaver
Weaver = require('../src/Weaver')

describe 'WeaverPlugin test', ->
  it 'should list available plugins', ->
    Weaver.Plugin.list().then((plugins) ->
      expect(plugins).to.have.length.be.at.least(0)
    )

  it 'should get a single plugin', ->
    Weaver.Plugin.load('calculator').then((plugin) ->
      assert.equal(plugin.getPluginName(), 'calculator')
    )

  it 'should raise an error when plugin is not found', ->
    Weaver.Plugin.load('someplugin').should.be.rejected

  it 'should call plugin functions on calculator', ->
    plugin = null
    Weaver.Plugin.load('calculator').then((p) ->
      plugin = p
      plugin.getBase()
    ).then((base) ->
      assert.equal(base, 'Base-10')

      plugin.add(5, 8)
    ).then((result) ->
      assert.equal(result, 13)

      plugin.subtract(140, 40)
    ).then((result) ->
      assert.equal(result, 100)
    )

  it 'should raise an error when a function is incorrectly called', ->
    Weaver.Plugin.load('calculator').then((plugin) ->
      plugin.add(4) # Missing field y
    ).should.be.rejected

  it.skip 'should deny execution access if not permitted', ->

  it.skip 'should be able to give role access to plugin execution', ->

  it.skip 'should be able to give user access to plugin execution', ->

  it.skip 'should not list a plugin of which access is not permitted', ->
