{
    var defs = options.defs || Object.create(null), incLoc = options.incLoc || Object.create(null), incLib = options.incLib || Object.create(null);
    var absent = false, en = true, stack = [];
    function include(file, lib) {
        var inc = (lib ? incLib : incLoc)[file];
        if (inc) return peg$parse(inc, { incLoc : incLoc, incLib : incLib });
        (lib ? incLib : incLoc)[file] = null;
        absent = true;
        return lib ? ('//[<' + file + '>]') : ('//["' + file + '"]');
    }
    function getAbsent(inc) {
        var r = [];
        if (absent) for (var fn in inc) if (inc[fn] === null) r.push(fn);
        return r;
    }
    function push(e) {
        stack.push(en);
        en = en && e;
    }
    function pop() { en = stack.pop(); }
}

////////// Unit of code

Unit = i:Item l:Lines { return { 
    defs   : defs, 
    incLoc : getAbsent(incLoc), 
    incLib : getAbsent(incLib),
    result : i + '\n' + l
}; }

Lines = l:Line* { return en ? l.join('\n') : ''; }

Line = "\n" i:Item { return i; }

Item = Directive / CodeLine ;

////////// Directives

Directive = is "#" is v:(Define / IncludeLib / IncludeLocal / If) { return v; }

Define = "define" is i:Identifier a:ArgList? v:Item { if(en) defs[i] = { v : v, a : a }; return ''; }
    ArgList = "(" is i:Identifier l:COMMAArg* ")" is { return [i].concat(l); }
        COMMAArg = "," is i:Identifier { return i; }

If = (IfdefName / IfndefName / IfExp) l:Lines i:ElifLines* e:ElseLines? Endif { return l + i.join('') + (e || ''); }

    IfdefName  = "ifdef"  is i:Identifier { push(typeof defs[i] !== 'undefined'); }
    IfndefName = "ifndef" is i:Identifier { push(typeof defs[i] === 'undefined'); }
    IfExp      = "if"     is e:Expression { push(e !== 0); }

    ElifExp = "\n" is "#" is "elif"  is e:Expression { en = (en === false) ? (e !== 0) : null; }
        ElifLines = ElifExp l:Lines { return l; }
    Else    = "\n" is "#" is "else"  is { en = (en === false); }
        ElseLines = Else l:Lines { return l; }
    Endif   = "\n" is "#" is "endif" is { pop(); }

IncludeLib   = "include" is  "<" f:FileName  ">" is { return en ? include(f, true ) : ''; }
IncludeLocal = "include" is "\"" f:FileName "\"" is { return en ? include(f, false) : ''; }
    FileName = a:(IdChar / [/\\.])+ { return a.join(''); }

////////// Expressions 

Expression = Exp0 ;

Exp0 = Const / DefToInt ;

DefToInt = i:Identifier { 
    var v = defs[i];
    if(!v || !v.v) return error('Name \'' + i + '\' undefined.');
    return parseInt(v.v);
}

Const = DecimalConst / OctalConst ;
    DecimalConst = a:[1-9] b:[0-9]* { return parseInt(  a + b.join('')); }
    OctalConst   =     "0" a:[0-7]* { return parseInt('0' + a.join(''), 8); }

////////// Line of code

CodeLine = s:is !"#" i:CodeItem* { return s + i.join(''); }

CodeItem = !"\n" i:(LineComment / LongComment / LineAdd / String / Char / Macro / nn) { return i; }

LineAdd = "\\" is "\n" { return ''; }


////////// Code


Macro = i:Identifier "(" w1:ws c:Code a:("," ws Code)* ")" w2:ws {
    if (defs[i] && defs[i].a) {
        console.log();
    } else
        return i + '(' + w1 + c + a.join('') + ')' + w2;
}

Code = Macro / String / Char ;

////////// Strings

String = '"' s:NotDQ* '"' { return '"' + s.join('') + '"'; }
NotDQ = !'"' s:(BS / .) {return s; }
Char = "'" s:NotSQ* "'" { return '\'' + s.join('') + '\''; }
NotSQ = !'\'' s:(BS / .) { return s; }
BS = bs:("\\" .) { return bs.join(''); }

////////// Characters

Identifier = !Keyword a:IdNondigit b:IdChar* is {return a + b.join('')} ;

Digit      = [0-9] ;
HexDigit   = [0-9] / [a-f] / [A-F] ;
IdChar     = [a-z] / [A-Z] / [0-9] / [_] / UniversalCharacter ;
IdNondigit = [a-z] / [A-Z]         / [_] / UniversalCharacter ;

UniversalCharacter = "\\u" HexQuad / "\\U" HexQuad HexQuad ;

HexQuad = HexDigit HexDigit HexDigit HexDigit ;

//////// Keywords

Keyword = ( "auto" / "break" / "case" / "char" / "const" / "continue" / "default" / "double" / "do" / "else" / "enum" / "extern" / "float"
      / "for" / "goto" / "if" / "int" / "inline" / "long" / "register" / "restrict" / "return" / "short" / "signed" / "sizeof" / "static"
      / "struct" / "switch" / "typedef" / "union" / "unsigned" / "void" / "volatile" / "while" / "_Bool" / "_Complex" / "_Imaginary"
      / "_stdcall" / "__declspec" / "__attribute__" / "namespace" / "using" / "true" / "false"
    ) !IdChar ;

//////// Comments and spaces 

ws = a:(WhiteSpace       / LongComment / LineComment)* { return a.join(''); }
is = a:(InlineWhiteSpace / LongComment)*               { return a.join(''); }

LongComment = "/*" a:(!"*/" .)* "*/" { return ''; }
LineComment = "//" a:nn*      { return ''; }

nn = !"\n" v:. { return v; }

InlineWhiteSpace = a:[ \t\u000B\u000C]     { return a; }
WhiteSpace       = a:[ \n\r\t\u000B\u000C] { return a; }

EOF = !_ ;
_ = . ;

