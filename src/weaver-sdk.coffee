printer = require('./printer')

module.exports = Weaver =
  hello: printer

Weaver.hello()
  
# Export to window if in browser
window.Weaver = Weaver if window?