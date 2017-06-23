module.exports =
  admin:
    username: 'admin'
    password: '$2a$10$CnY1NFwHHo1v0qiF/rKgIOWAxUOA5Znh7kMPoh.Ru98uX9CZ7MPqC'
    generatePassword: false

  auth:
    secret: 'mysupersecretstring'
    expire: '7d'
    salt: 10

  projectPool: [
    {
      database: 'http://weaver-database:9474'
      fileServer:
        endpoint: 'http://file-system:9000'
        accessKey: 'NYLEXGR6MF2IE99LZ4UE'
        secretKey: 'CjMuTRwYPcneXnGac2aQH0J+EdYdehTW4Cw7bZGD'
      tracker:
        enabled: true
        host: 'trackerdb'
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
      enabled: false
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
