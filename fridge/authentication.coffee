class Signin
  constructor: () ->

  username: (username) ->
    username

  token: (token) ->
    token


Promise     = require('bluebird')
randomBytes = Promise.promisify(require('crypto').randomBytes)
cuid        = require('cuid')

module.exports = (weaver, user) ->

# Generate Token ID
  randomBytes(12).then((buf) ->

# Save Token ID
    tokenId = buf.toString('hex')

    # Create Token
    token = weaver.tokens.create({id: tokenId})

    # Create Session
    session = weaver.sessions.create()

    # Somehow the order below seems to matter (?)
    token.link('session', session)
    session.link('token', token)

    user.link('session', session)
    session.link('user', user)

    tokenId
  )