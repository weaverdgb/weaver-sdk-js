module.exports =
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

