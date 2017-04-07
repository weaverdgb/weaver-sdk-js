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
        value: 'The choosen One Craaaap xD'
        type: 'String'
      }

      for i in [0..100]
        data[0][i] = {"#{i}":cell}

      console.log Weaver.currentProject()
      console.log Weaver.currentUser()




      bbReport.createExcelReport(data,'file.xlsx', projectId)
    ).then((res) ->
      console.log res
      console.log "http://localhost:9487/file/downloadByID?payload=%7B%22id%22%3A%22#{res.split('-')[0]}%22%2C%22target%22%3A%22#{Weaver.currentProject().projectId}%22%2C%22authToken%22%3A%22#{Weaver.currentUser().authToken}%22%7D"

    )
