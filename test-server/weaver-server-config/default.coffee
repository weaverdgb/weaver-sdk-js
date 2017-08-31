module.exports =
  admin:
    username: 'admin'
    password: '$2a$10$CnY1NFwHHo1v0qiF/rKgIOWAxUOA5Znh7kMPoh.Ru98uX9CZ7MPqC'
    generatePassword: false

  auth:
    secret: 'mysupersecretstring'
    expire: '7d'
    salt: 10

  application:
    openUserCreation: true
    wipe: true
    projectpool: 'PostgreSQLProjectPool'
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
    database:
      url: 'http://localhost:4567'

    fileServer:
      endpoint: 'http://localhost:9000'
      accessKey: 'NYLEXGR6MF2IE99LZ4UE'
      secretKey: 'CjMuTRwYPcneXnGac2aQH0J+EdYdehTW4Cw7bZGD'
      uploads: 'uploads/'

    snmp:
      enabled: false
      ipMonitor: 'localhost'
      trapPort: 1116
      agentPort: 1117
      heartbeatsInterval: 5000
      agentAddress: 'localhost'

  logging:
    console: 'debug'
    file:    'warn'
    logFilePath:
      config: './logs/weaver.config'
      code: './logs/weaver.code'
      usage: './logs/weaver.usage'
      auth: './logs/weaver.auth'
