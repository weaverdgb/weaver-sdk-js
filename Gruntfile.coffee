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
          
      uglify:
        build:
          src: 'dist/weaver-sdk.js',
          dest: 'dist/weaver-sdk.min.js'
  )
  
  # Default task
  grunt.registerTask('default', ['clean', 'coffee', 'browserify', 'uglify'])