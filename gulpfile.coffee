gulp        = require('gulp')
clean       = require('gulp-clean')
coffee      = require('gulp-coffee')
concat      = require('gulp-concat')
browserify  = require('browserify')
uglify      = require('gulp-uglify')
source      = require('vinyl-source-stream')
buffer      = require('vinyl-buffer')
plumber     = require('gulp-plumber')
notify      = require("gulp-notify")

errorString = "<%= error.name %>: " +
					    "<%= error.message %> " +
					    "in file <%= error.filename.substr(error.filename.lastIndexOf('/') + 1) %> " +
					    "on line <%= error.location.first_line + 1 %>:" +
					    "<%= error.location.first_column %>"

gulp.task('clean', ->
  gulp.src(['./dist', './tmp'], read: false, allowEmpty: true)
    .pipe(clean())
)

gulp.task('clean-dist', ->
    gulp.src('./dist/weaver-sdk.full.js')
      .pipe(plumber())
      .pipe(clean())
)

gulp.task('coffee', ->
  gulp.src('./src/**/*.coffee')
    .pipe(plumber(errorHandler: notify.onError(errorString)))
    .pipe(coffee())
    .pipe(gulp.dest('./tmp'))
)

gulp.task('concat', ->
  gulp.src('./tmp/**/*.js')
    .pipe(plumber())
    .pipe(concat('weaver-sdk.js'))
    .pipe(gulp.dest('./dist'))
)

gulp.task('browserify', ->
  browserify({
    entries: './tmp/Weaver.js',
    ignoreMissing: true
  }).bundle()
    .on('error', (error) ->
      console.log(error)
      @emit('end')
    )
    .pipe(source('weaver-sdk.full.js'))
    .pipe(buffer())
    .pipe(gulp.dest('./dist'))
)

gulp.task('uglify', ->
  gulp.src('./dist/weaver-sdk.full.js')
    .pipe(plumber(errorHandler: notify.onError(errorString)))
    .pipe(uglify())
    .pipe(concat('weaver-sdk.full.min.js'))
    .pipe(gulp.dest('./dist'))
)

gulp.task('dev', gulp.series('clean', 'coffee', 'browserify'))

gulp.task('watch', ->
  gulp.watch(['./src/**/*.coffee', './config/**/*.coffee'], gulp.series('dev'))
)

gulp.task('default', gulp.series('dev', 'watch'))

gulp.task('dist', gulp.series('dev', 'uglify', 'clean-dist'))
