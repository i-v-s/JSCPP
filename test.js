var request = require("request");
var parser  = require("./lib/cpp");
var prep    = require("./lib/prep");
var fs      = require('fs');


//console.log(parser.parse('020'));

//console.log(parser.parse('136'));

//console.log(prep.parse('#define t5 123 \n int test = 4;\n '));

//console.log(parser.parse('int A() { int t; }'));

var code;

function parse(input, parser) {
    function gen(c, n) {
        var r = '';
        while(--n >= 0) r += c;
        return r;
    }
    try {
        return parser.parse(input, {tt:'TTTEST'});
    } catch (e) {
        console.log(e.message);
        if (e.location) {
            var l = e.location, start = l.start, end = l.end, ia = input.split('\n').slice(start.line - 1, end.line);
            for (var x = 0; x < ia.length; x++) {
                if (!x) {
                    if (start.column > 50) {
                        console.log('... ' + ia[0].substr(start.column - 50));
                        console.log(gen(' ', 50 + 3) + '^');
                    } else {
                        console.log(ia[0]);
                        console.log(gen(' ', start.column - 1) + '^');
                    }
                }
            }
        }
    }
}

function preprocessor(input, cb) {
    var r = parse(input, prep);
    if (!r) return;
    if (r.incLoc.length || r.incLib.length) {

    } else cb(r.result);
}

//console.log(cpp);

var cpp = fs.readFileSync('feature_alignment.cpp', 'utf8');

console.log(parse(cpp, prep));

code = parse(cpp, parser/*'int g = 59; int gg;' +
    'class Test { int B; };' +
    'int A() { typedef int Integer;' +
        'float t, a = 27; int b = a;' +
        't = 5; {' +
            'int u;' +
        '} }' +
    'void printf(int v);' +
    'int main() {' +
        'int x = 22;'+
        'printf(x);'+
        'return x;' +

    '}'*/
);

if (code) {
    console.log(code);

    var f = new Function('$', code);
    var $ = Object.create(null);

    $.printf = function(v) {
        console.log('printf:', v);
    }
    f($);
    var r = $.main();

    console.log('result:', r);
}

