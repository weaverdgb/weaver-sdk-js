module.exports =
  services:
    database:
      url: 'http://postgresql-connector:4567'

    fileServer:
      endpoint: 'http://file-system:9000'

  pluggableServices:
    calculator: 'http://calculator:1414'
