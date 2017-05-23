module.exports = (grunt) ->
  require("load-grunt-tasks")(grunt)
  grunt.registerTask "build", "to build", ["clean", "copy", "peg", "dist"]
  grunt.registerTask "dist", "to make distribution version", ["browserify", "shell", "concat", "uglify"]
  grunt.registerTask "default", "to watch & compile", ["build", "watch"]
  grunt.registerTask "test", "to test", ["mochaTest"]
  pkg = grunt.file.readJSON "package.json"
  grunt.initConfig
    pkg: pkg

    copy:
      build:
        cwd: "src"
        src: ["**", "!**/*.coffee"]
        dest: "lib"
        expand: true

    clean:
      build:
        src: ["lib", "dist"]

    browserify:
      dist:
        files:
          "dist/JSCPP.js": ["lib/**/*.js"]

    uglify:
      dist:
        files:
          "dist/JSCPP.es5.min.js": ["dist/JSCPP.es5.js"]

    shell:
      dist:
        command: "node node_modules/traceur/traceur --out dist/JSCPP.es5.js --script dist/JSCPP.js"

    concat:
      options:
        separator: ";"
      dist:
        src: ["node_modules/traceur/bin/traceur-runtime.js", "dist/JSCPP.es5.js"]
        dest: "dist/JSCPP.es5.js"

    mochaTest:
      test:
        options:
          reporter: "spec",
          captureFile: "test.log"
          require: "coffee-script/register"

        src: ["test/**/*.coffee"]

    peg:
      build:
        cwd: "pegjs"
        src: ["**/*.pegjs"]
        dest: "lib"
        ext: ".js"
        expand: true

    watch:
      peg:
        files: "pegjs/**/*.pegjs"
        tasks: ["newer:peg"]
      copy:
        files: ["src/**", "!src/**/*.coffee"]
        tasks: ["newer:copy"]
