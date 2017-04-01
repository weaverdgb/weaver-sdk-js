require("./test-suite")

describe 'BB reporting pluging testing', ->

  it 'should list available plugins', ->
    Weaver.Plugin.list().then((plugins) ->
      assert.equal(plugins.length, 3)
    )

  it 'should get a briefbuilder-reporting plugin', ->
    Weaver.Plugin.load('briefbuilder-reporting').then((plugin) ->
      assert.equal(plugin.getPluginName(), 'briefbuilder-reporting')
    )

  it 'should do something for the excel generator', ->
    Weaver.Plugin.load('briefbuilder-reporting').then((bbReport) ->

      projectId = Weaver.currentProject().projectId

      data = {
        0:{}
      }

      cell = {
        value: 'The value'
        type: 'String'
      }

      for i in [0..100]
        data[0][i] = {"#{i}":cell}

      bbReport.createExcelReport(data,'file.xlsx', projectId)
    ).then((res) ->
      console.log res
    )
