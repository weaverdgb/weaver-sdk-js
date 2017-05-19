module.exports =
  admin:
    username: 'admin'
    password: 'admin'
    generatePassword: false

  auth:
    secret: 'mysupersecretstring'
    expire: '7d'

  projectPool: [
    {
      database: 'http://localhost:9474'
      fileServer:
        endpoint: 'http://localhost:9000'
        accessKey: 'NYLEXGR6MF2IE99LZ4UE'
        secretKey: 'CjMuTRwYPcneXnGac2aQH0J+EdYdehTW4Cw7bZGD'
      tracker:
        enabled: true
        host: 'localhost'
        port: 3306
        user: 'root'
        password: 'K00B88HQB1UV9MZ7YYUP'
        database: 'trackerdb'
    }
  ]

  application:
    wipe: true
    singleDatabase: true
    sounds:
      muteAll: false
      loaded:  true
      errors:  true

  server:
    port: 9487
    cors: true

  comm:
    http:
      enable: true
    socket:
      enable: true

  services:
    projectController:
      endpoint: 'http://localhost:9888'

    snmp:
      enabled: true
      ipMonitor: 'localhost'
      trapPort: 1116
      agentPort: 1117
      heartbeatsInterval: 5000
      agentAddress: 'localhost'

  logging:
    console: 'error'
    file:    'warn'
    logFilePath:
      config: './logs/weaver.config'
      code: './logs/weaver.code'
      usage: './logs/weaver.usage'
