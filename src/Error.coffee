# Signature error using code and message
module.exports = (code, message) -> 
  error = new Error(message)
  error.code = code
  error