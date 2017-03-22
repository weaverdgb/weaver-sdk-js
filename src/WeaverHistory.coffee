Weaver      = require('./Weaver')
CoreManager = Weaver.getCoreManager()



class WeaverHistory

  constructor: () ->



  getHistory: (id)->
    CoreManager.getHistory({id})

# Export
module.exports = WeaverHistory
