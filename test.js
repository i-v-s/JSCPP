var request = require("request");
var parser  = require("./lib/cpp");
var prep    = require('./lib/prep');
var libs    = require('./libs');
var fs      = require('fs');


//console.log(parser.parse('020'));

//console.log(parser.parse('136'));

//console.log(prep.parse('#define t5 123 \n int test = 4;\n '));

//console.log(parser.parse('int A() { int t; }'));

var code;

function handler(fn, input, e) {
    function gen(c, n) {
        var r = '';
        while(--n >= 0) r += c;
        return r;
    }
    if (e.location) {
        var l = e.location, start = l.start, end = l.end;
        var ia = input.split('\n').slice(start.line - 1, end.line);
        console.log('File ' + fn, start);
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
    console.log(e.message);
}

function parse(input, fn, parser, options) {
    try {
        return parser.parse(input, options || {});
    } catch (e) {
        handler(fn, input, e);
    }
}

var libUrl = [
    'https://raw.githubusercontent.com/uzh-rpg/rpg_svo/master/svo/include/',
    'https://raw.githubusercontent.com/uzh-rpg/rpg_vikit/master/vikit_common/include/'
];

function getFile(fn, urls) {
    console.log('Loading:', fn);
    return new Promise((resolve, reject) => {
        var count = 0, solved = false;
        for (var url of urls) {
            count++;
            request(url + fn, (error, response, body) => {
                count--;
                if (error || response.statusCode !== 200) {
                    var msg = error || url + fn + ' status: ' + response.statusCode;
                    console.log(msg);
                    if(!count && !solved) reject(msg);
                } else if (!solved) {
                    console.log(fn, 'Ok');
                    resolve(body);
                    solved = true; 
                }
            });
        }
    });
}

function preprocessor(input, fileName, options) {
    function pf(resolve, reject) {
        if (!options) options = { incLoc : Object.create(null), incLib : Object.create(null), handler : handler };
        var r = parse(input, fileName, prep, options);
        if (!r) return reject();
        if (r.incLoc.length || r.incLib.length) {
            Promise.all(r.incLib.map(fn => getFile(fn, libUrl))).then(bodies => {
                for (var x in r.incLib)
                    options.incLib[r.incLib[x]] = bodies[x];
                pf(resolve, reject);
            });
        } else resolve(r.result);
    }
    return new Promise(pf);
}

//console.log(cpp);
var fn = 'feature_alignment.cpp';
var cpp = fs.readFileSync(fn, 'utf8');

preprocessor(cpp, fn, { incLib : libs, handler : handler }).then(cpp => {
    //console.log(cpp);
    for(var x = 0; x < 7; x++)
        cpp = cpp.replace(/\n *\n *\n/g, '\n\n');
    fs.writeFileSync('source.cpp', cpp);
    var code = parse(cpp, fn, parser, { handler : handler });
    console.log(code);
});

//console.log(parse(cpp, prep));

//code = parse(cpp, parser);

/*'int g = 59; int gg;' +
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
//);

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

