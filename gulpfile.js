var gulp  = require('gulp');
var peg   = require('gulp-peg');
var gutil = require('gulp-util');

var paths = {
    build: "lib"
};

function pegTask(src, options) {
    return function() {
        return gulp.src(src).pipe(peg(options).on("error", gutil.log)).pipe(gulp.dest(paths.build));
    }
}

gulp.task('peg:prep', pegTask('pegjs/prep.pegjs'));
gulp.task('peg:cpp',  pegTask('pegjs/cpp.pegjs', { allowedStartRules : ['Unit', 'ClassDef']}));
gulp.task('peg', ['peg:cpp', 'peg:prep']);

gulp.task('default', ['peg']);
