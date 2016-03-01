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

      browserify:
        main:
          src: 'tmp/**/*.js'
          dest: 'dist/weaver-sdk.js'
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
          src: 'dist/weaver-sdk.js',
          dest: 'dist/weaver-sdk.min.js'

      copy:
        toAngular:
          files: [
            {src: ['dist/**'], dest: '../weaver-app-angular/weaver-sdk-js/', filter:'isFile', expand:true}
            {src: ['dist/**'], dest: '../weaver-studio/weaver-sdk-js/', filter:'isFile', expand:true}
          ]

      watch:
        options:
          spawn: false
        files: ['**/*.coffee', '!_SpecRunner.html', '!.grunt']
        tasks: ['default']
  )

  # Default task
  grunt.registerTask('default', ['clean', 'coffee', 'browserify', 'copy:toAngular', 'watch'])

  # Dist
  grunt.registerTask('dist', ['clean', 'coffee', 'browserify', 'uglify'])