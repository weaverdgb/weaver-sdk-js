module.exports = (grunt) ->

  # Load all grunt tasks
  require('load-grunt-tasks')(grunt)

  # Task configuration
  grunt.initConfig(
      clean:
        before:
          src: ['dist', 'tmp']
        after:
          src: ['dist', 'tmp']
        dist:
          src: ['dist/weaver-sdk.full.js']

      coffee:
        main:
          options:
            sourceRoot: ''
            sourceMap: false
          cwd: 'src/'
          src: '**/*.coffee'
          dest: 'tmp'
          expand: true
          ext: '.js'

      concat: {
        main: {
          src: ['tmp/**/*.js'],
          dest: 'dist/weaver-sdk.js'
        }
      },

      browserify:
        main:
          src: 'tmp/**/*.js'
          dest: 'dist/weaver-sdk.full.js'
          ignore: ['tmp/WeaverFile.js', 'tmp/WeaverNode.js', 'tmp/WeaverRelation.js', 'tmp/WeaverSystemNode.js', 'tmp/WeaverProject.js', 'tmp/WeaverQuery.js', 'tmp/WeaverACL.js', 'tmp/WeaverRole.js', 'tmp/WeaverUser.js', 'tmp/WeaverFileBrowser.js', 'tmp/WeaverModel.js']
          options:
            plugin: [
              [
                'remapify', [
                  'src': '**/*.js'
                  'expose': ''
                  'cwd': './tmp/'
                ]
              ]
            ]

      uglify:
        build:
          src: 'dist/weaver-sdk.full.js',
          dest: 'dist/weaver-sdk.full.min.js'

      copy:
        toAngular:
          files: [
            {src: ['dist/**'], dest: '../weaver-data-workbench/sdk_temp/', filter:'isFile', expand:true}
          ]

      watch:
        options:
          spawn: false
        files: ['**/*.coffee', '!_SpecRunner.html', '!.grunt']
        tasks: ['default']
  )

  # Default task
  grunt.registerTask('default', ['clean', 'coffee', 'browserify', 'copy:toAngular', 'watch'])

  # Dist task
  grunt.registerTask('dist', ['clean', 'coffee', 'browserify', 'uglify', 'clean:dist'])
  # grunt.registerTask('dist', ['clean', 'coffee', 'browserify', 'clean:dist'])

  # Development task
  grunt.registerTask('dev', ['clean', 'coffee', 'browserify'])
