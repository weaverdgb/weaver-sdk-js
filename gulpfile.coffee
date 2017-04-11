gulp        = require('gulp')
clean       = require('gulp-clean')
coffee      = require('gulp-coffee')
concat      = require('gulp-concat')
browserify  = require('gulp-browserify')
uglify      = require('gulp-uglify')

gulp.task('clean', ->
  gulp.src(['./dist', './tmp'], read: false, allowEmpty: true)
    .pipe(clean())
)

gulp.task('clean-dist', ->
    gulp.src('./dist/weaver-sdk.full.js')
      .pipe(clean())
)

gulp.task('coffee', ->
  gulp.src('./src/**/*.coffee')
    .pipe(coffee())
    .pipe(gulp.dest('./tmp'))
)

gulp.task('concat', ->
  gulp.src('./tmp/**/*.js')
    .pipe(concat('weaver-sdk.js'))
    .pipe(gulp.dest('./dist'))
)

gulp.task('browserify', ->
  gulp.src('./tmp/Weaver.js')
    .pipe(browserify())
    .pipe(concat('weaver-sdk.full.js'))
    .pipe(gulp.dest('./dist'))
)

gulp.task('uglify', ->
  gulp.src('./dist/weaver-sdk.full.js')
    .pipe(uglify())
    .pipe(concat('weaver-sdk.full.min.js'))
    .pipe(gulp.dest('./dist'))
)

gulp.task('watch', ->
  gulp.watch('**/*.coffee', gulp.series('clean', 'coffee', 'browserify'))
)

gulp.task('default', gulp.series('clean', 'coffee', 'browserify', 'watch'))

gulp.task('dist', gulp.series('clean', 'coffee', 'browserify', 'uglify', 'clean-dist'))

gulp.task('dev', gulp.series('clean', 'coffee', 'browserify'))
