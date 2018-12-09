Weaver      = require('./Weaver')

class WeaverNarql

  constructor: (@query, @target) ->

  find:  ->
    Weaver.getCoreManager().narql(@query)

# Export
module.exports = WeaverNarql
