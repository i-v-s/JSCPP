{
    /////// Состояние
    var stack = [], global = Object.create(null), declType, returnType, userType, className;

    function findType(name) {
        for (var x = stack.length - 1; x >= 0; x--)
            if (typeof stack[x].t[name] !== 'undefined')
                return stack[x].t[name];
    }

    //////// Корневой класс для всех типов
    function Type() { }
    Type.prototype = {
        typeName : function() { return this.tn; },
        ptrOrder : function() { return this.p || 0; },
        js       : function() { return this.j || this.c; },
        isConst  : function() { return typeof this.c !== 'undefined'; },
        from     : function(v) {
            if (typeof this.cvt !== 'function')
                return error('Method cvt() not defined for type ' + this.typeName());
            var f = this.cvt(v);
            if (f === null) {
                if (v.isConst()) this.c = v.c; else this.j = v.j;
                return;
            }
            if (typeof f !== 'function')
                return error('Unable to convert \'' + v.typeName() + '\' to \'' + this.typeName() + '\': method undefined');
            if (v.isConst())
                this.c = Function('$', f('$'))(v.c);
            else
                this.j = f(v.j);
        },
        // бинарные операторы
        bi : function(op, v2) {
            if (typeof this._bi !== 'function')
                return error('Method _bi() not defined for type ' + this.typeName());
            var b = this._bi(op, v2), type = findType(b.t);
            if (this.isConst() && v2.isConst()) {
                var c = Function('$1', '$2', b.f('$1', '$2'))(this.c, v2.c);
                return new type({ c : c });
            } else {
                var j = b.f(this.js(), v2.js());
                return new type({ j : j });
            }
        }
    };
    /////// Скалярные типы
    function Integer(width, signed) { this.w = width; this.s = signed; }
    Integer.prototype = new Type();
    Integer.prototype.cvt = function(from) {
        if (from instanceof Float) return function(a) { return '(' + a + '|0)'; }
        if (from instanceof Integer) return null;
    }
    
    function Float  (width) { this.w = width; }
    Float.prototype = new Type();
    Float.prototype.cvt = function(from) {
        if (from instanceof Float || from instanceof Integer) return null;
    }
    Float.prototype._bi = function(op, v2) {
        if (v2 instanceof Float || v2 instanceof Integer) return { 
            f : function(a, b) { return '(' + a + op + b + ')'; },
            t : (this.w < v2.w) ? v2.typeName() : this.typeName()
        };
        error('Operator \'' + op + '\' wrong types.');
    }
    ////// Function type

    function Func(type, name, args) {
        this.t = type;
        this.n = name;
        this.a = args;
    }
    Func.prototype = new Type();
    Func.prototype.mangledName = function() { return [this.n].concat(this.a.map(function(a){ return a.t.prototype.tn; })).join('$')};
    Func.prototype.match = function(a) {
        var l1 = this.a.length, l2 = a.length;
        if (l1 < l2) return false;
        if (l1 > l2) for (var x = l2; x < l1; x++) if (typeof this.a[x].i !== 'undefined') return false;
        for (var x = 0; x < l2; x++) {

        }
        return true;
    };
    Func.prototype.exec = function(args) {
        var l = this.a ? this.a.length || 0 : 0;
        if (!(args instanceof Array)) args = [args];
        if (args.length != l) return error('Argument count mismatch.');
        for (var x = 0; x < l; x++)
            args[x] = (new this.a[x].t(args[x])).js();
        var j = this.n + '(' + args.join(',') + ')';
        return new this.t({ j : j });
    };

    function FuncSet(name) {
        this.n = name;
        this.f = [];
    }

    function Namespace(name) {
        this.n = name;
    }
    //FuncSet.prototype.

    function begin(section) {
        stack.push({ 
            v : Object.create(null),
            t : Object.create(null),
            s : section
        });
    }
    begin();

    /////// Словарь типов
    var types0 = stack[0].t;
    
    function defineType(name, proto) {
        var l = stack.length;
        if (!l) return error("Stack is empty");
        var types = stack[l - 1].t;
        if (findType(name))
            return error("Type '" + name + "' redeclared.");

        var type = function(v) { // Конструктор значений
            if (typeof v === 'string') { // Создаём переменную с заданным именем
                this.j = v;
                this.n = v;
            } else if (v instanceof Type) {
                this.from(v);
            } else {
                if (typeof v.c !== 'undefined') this.c = v.c; // нативное значение
                if (typeof v.j === 'string')    this.j = v.j; // значение из выражения js
            }
        };
        proto.tn = name;
        type.prototype = proto;
        types[name] = type;
    }
    
    // Types: 
    //   n - name
    //   t - type i(nt), f(loat), b(ool), c(lass), s(struct), u(nion), v(oid), (functio)n
    //   w - width, bytes
    //   s - signed, bool
    //   v - member vars
    defineType('void',   new Type());
    defineType('char',   new Integer(1, true));
    defineType('int',    new Integer(4, true));
    defineType('long',   new Integer(4, true));
    defineType('float',  new Float(4));
    defineType('double', new Float(8));

    function findVar(name) {
        for (var x = stack.length - 1; x >= 0; x--)
            if (typeof stack[x].v[name] !== 'undefined')
                return stack[x].v[name];
    }
    function defineFunction(func) {
        //debugger;
        if (!func instanceof Func) return error('Not function: ' + func);
        var l = stack.length;
        if (!l) return error('Stack is empty');

        var v, name = func.n, mn = func.n;//mangledName();
        if (global[mn] && global[mn].b && func.b) return error('Function \'' + name + '\' body redeclared.');
        var fs = findVar(name);// || new FuncSet(name);
        //console.log('defineFunction:', name);
        if (fs) {

            //return error("Function '" + variable.n + "' redeclared.");
        } else {
            stack[l - 1].v[name] = func;
            global[mn] = func;
        }
        //console.log('Defined function', name, func);
    }
    function declVar(variable) {
        var l = stack.length;
        if (!l) return error('Stack is empty');
        if (findVar(variable.n))
            return error("Variable '" + variable.n + "' redeclared.");
        if (stack[l - 1].s) variable.s = stack[l - 1].s;
        stack[l - 1].v[variable.n] = variable;
    }
}

Unit = ws i:UnitItem* {
    var vars = stack[0].v, varNames = [], r = [];
    for (var x in vars) varNames.push(x);
    if (varNames.length) r.push('var ' + varNames.join(',') + ';');
    for(var x in i) if (i[x].j) r.push(i[x].j);
    return r.join('\n');
}

UnitItem = Function / FunctionPrototype / DeclarationStatement / TypedefStatement / ClassStatement / Namespace;

////////// Namespaces

Namespace = NamespaceHead i:UnitItem* "}" ws {
    stack.pop();
}

NamespaceHead = "namespace" ws n:Identifier ws "{" ws {
    var ns = new Namespace(n);
    declVar(ns);
    begin();
    ns.v = stack[stack.length - 1];
}

////////// Functions

FunctionPrototype = h:FunctionHead ";" ws {
    defineFunction(h);
    var name = h.n;//mangledName();
    return { j : 'var ' + name + '=$.' + name + ';' };
}

Function = h:FunctionStart c:CodeBlockBody {
    var js = c.j;
    if (!js) js = '{}';
    else if (c.d && c.d.length) js = js[0] + 'var ' + c.d.join(',') + ';' + js.substr(1);
    var a = h.a ? h.a.join(',') : '';
    returnType = undefined;
    return { j : '$.' + h.n + '=function ' + h.n + '(' + a + ')' + js + ';' };
}

FunctionStart = h:FunctionHead "{" ws {
    returnType = h.t;
    begin();
    if (h.a) for (var x in h.a) {
        var a = h.a[x];
        declVar(a.n, a.t);
    }
    return h;
}

FunctionHead = t:Type n:Identifier "(" ws a:ArgumentList? ")" ws { return new Func(t, n, a || []); }

ArgumentList = a1:Argument a:COMMAArgument* { return [a1].concat(a); }

COMMAArgument = "," ws a:Argument { return a; }

Argument = t:Type n:Identifier? i:ArgumentInitializer? {
    return {n : n, t : t, i : i};
}

ArgumentInitializer = EQU c:Const { return c; }

CodeBlock = CodeBlockStart b:CodeBlockBody { return b; }
    
CodeBlockBody = c:Statement* "}" ws {
    var js = [];
    for (var x in c) if (c[x] && c[x].j) js.push(c[x].j); 
    var vars = stack.pop().v, varNames = [];
    for (var x in vars) varNames.push(x);
    js = js.join('');
    return { d : varNames, j : (js !== '') ? '{' + js + '}' : '' }; 
}

CodeBlockStub = "{" ws CBSItem* "}" ws ;
    CBSItem = CodeBlockStub / CharConst / StringConst / (!"}" .)

CodeBlockStart = "{" ws { begin(); }

Statement = DeclarationStatement / CodeBlock / ExpressionStatement / TypedefStatement / ClassStatement / ReturnStatement ;

ReturnStatement = 'return' ws e:Expression ';' ws { 
    var ec = new returnType(e); 
    return { j : 'return ' + (ec.j || ec.c) + ';' };
}

////////// Variable declarations

DeclarationStatement       = SetType d:    DeclarationList ";" ws { return {j : d}; }
MemberDeclarationStatement = SetType MemberDeclarationList ";" ws { return undefined; }

SetType = t:Type { declType = t; }

DeclarationList       = d:Declaration l: COMMADeclaration* { return d + l.join(); }
MemberDeclarationList = DeclareVar COMMAMemberDeclaration* { return undefined; }

COMMADeclaration       = COMMA d:Declaration { return d; }
COMMAMemberDeclaration = COMMA DeclareVar    { return undefined; }

Declaration = DeclareVar / DeclareInit ;

DeclareVar
    = n:Identifier ![=] { declVar(new declType(n)); return ''; }

DeclareInit
    = n:Identifier EQU e:Expression { declVar(new declType(n)); return n + '=' + (new declType(e)).js() + ';'; }

////////// Expressions
// t : c++ type (int32_t, uint32_t ...)
// j : compiled js ('a + 7')
// c : known const native value (7, 9)
// v : variable

ExpressionStatement = e:Expression ";" ws { return { j : e.js() + ';' }; }

Expression = Expr15 ;// Assign / RValue;

Expr15 = 
    a:Expr2 o:EQU b:Expr15 { return a.bi(o, b); } /
    Expr2 ;

Expr2 =
    f:Expr1 "(" ws e:Expression ")" ws { return f.exec(e); } /
    Expr1 ;

Expr1 = Variable / Const ;

/*Assign = l:LValue EQU r:RValue {
    var v = r.j || r.c;
    var js = (l.t == 'class') ? l.n + '["="](' + v + ')' : (l.n + '=' + v);
    return { j : js, t : l.t };
}*/

/*RValue = LValue / Const ;

LValue = Variable ;*/

Variable = n:Identifier { var v = findVar(n); if (v) return v; else error("Undeclared variable '" + n + "'."); }

////////// Classes and structures

ClassStatement = c:ClassDef d:DeclarationList? ";" ws { return {j : c + (d || '')}; };

    ClassDef = cd:ClassDefStart ClassMember* "}" ws {
        var data = stack.pop();
        var type = {n : cd.n, t : cd.t, v : data.v};
        defineType(type.n, type);
        return 'function ' + type.n + '(){}';
    }

        ClassDefStart = t:("class" / "struct") ws n:Identifier "{" ws {
            begin((t === 'class') ? 'pri' : 'pub');
            className = n;
            return { t : t[0], n : n};
        }

        ClassMember = MemberConstructorProto / MemberConstructorDef / MemberDestructorProto / MemberDestructorDef 
            / ClassSection / MemberDeclarationStatement ;

            MemberDestructorProto  = "~" ws a:MemberConstructorHead ";" ws ;
            MemberConstructorProto = a:MemberConstructorHead ";" ws ;
            MemberDestructorDef    = "~" ws a:MemberConstructorHead c:$CodeBlockStub { console.log('mdd:', a, c); }            
            MemberConstructorDef   = a:MemberConstructorHead i:ConstructorInits? c:$CodeBlockStub { console.log('mcd:', a, i, c); }
                MemberConstructorHead = t:Identifier &{ return t === className; } "(" ws a:ArgumentList? ")" ws { return a; }
                ConstructorInits = ":" ws i:ConstructorInit a:COMMAConstructorInit* { return [i].concat(a); }
                    ConstructorInit = m:Identifier "(" ws e:Expression ")" ws { return { m : m, e : e}; }
                    COMMAConstructorInit = "," ws i:ConstructorInit { return i; }

            ClassSection = s:(PRIVATE / PROTECTED / PUBLIC) ":" ws { stack[stack.length - 1].s = s; }
                PRIVATE   = "private"   ws { return 'pri'; }
                PROTECTED = "protected" ws { return 'pro'; }
                PUBLIC    = "public"    ws { return 'pub'; }

////////// Types

TypedefStatement = TYPEDEF SetType TypedefList ';' ws {}

TypedefList = n:TypedefName l:COMMATypedefName* { return n + l.join(); }

    COMMATypedefName = COMMA n:TypedefName {return n}
    TypedefName = n:Identifier { defineType(n, declType); }

Type = VOID / INT / LONG / FLOAT / DOUBLE / UserType;

VOID    = a:"void"   ws { return types0['void'  ]; }
LONG    = a:"long"   ws { return types0['long'  ]; }
INT     = a:"int"    ws { return types0['int'   ]; }
FLOAT   = a:"float"  ws { return types0['float' ]; }
DOUBLE  = a:"double" ws { return types0['double']; }

UserType = i:Identifier &{ return userType = findType(i); } { return userType; }

////////// Literals

Const = FloatConst / DecimalConst / OctalConst ;

DecimalConst = a:[1-9] b:[0-9]* { return new types0['int']({ c: parseInt(  a + b.join(''))}); }
OctalConst   =     "0" a:[0-7]* { return new types0['int']({ c: parseInt('0' + a.join(''), 8)}); }
FloatConst   = a:(DecimalFloatConstant) s:FloatSuffix? {
    return new types0['double']({ c : parseFloat(a)});
}
    DecimalFloatConstant = a:Fraction b:Exponent? { return a + b || ''; }
    / a:[0-9]+ b:Exponent { return a.join('') + b ; }
    ;

/*HexFloatConstant
    = a:HexPrefix b:HexFraction c:BinaryExponent? {return addPositionInfo({type:'HexFloatConstant', value:a+b+c||''});}
    / a:HexPrefix b:HexDigit+ c:BinaryExponent {return addPositionInfo({type:'HexFloatConstant', value:a+b.join('')+c});}
    ;*/

Fraction
    = a:[0-9]* "." b:[0-9]+ { return a.join('')+'.'+b.join('');}
    / a:[0-9]+ "." {return a.join('');}
    ;

/*HexFraction
    = a:HexDigit* "." b:HexDigit+ {return a.join('')+'.'+b.join('');}
    / a:HexDigit+ "." {return a.join('')+'.';}
    ;*/

    Exponent = a:[eE] b:[+\-]? c:[0-9]+ { return a + (b || "") + c.join(''); };

//BinaryExponent = a:[pP][+\-]? b:[0-9]+ {return a+b.join('');};


FloatSuffix = a:[flFL] ws {return a;}

StringConst = '"' s:NotDQ* '"' { return s.join(''); }
    NotDQ = !'"' s:(BS / .) {return s; }
CharConst = "'" s:NotSQ* "'" { return s.join(''); }
    NotSQ = !'\'' s:(BS / .) { return s; }
        BS = bs:("\\" .) { return bs.join(''); }

////////// Keywords

TYPEDEF = "typedef" ws ;

Keyword = ( "auto" / "break" / "case" / "char" / "const" / "continue" / "default" / "double" / "do" / "else" / "enum" / "extern" / "float"
      / "for" / "goto" / "if" / "int" / "inline" / "long" / "register" / "restrict" / "return" / "short" / "signed" / "sizeof" / "static"
      / "struct" / "switch" / "typedef" / "union" / "unsigned" / "void" / "volatile" / "while" / "_Bool" / "_Complex" / "_Imaginary"
      / "_stdcall" / "__declspec" / "__attribute__" / "namespace" / "using" / "true" / "false"
    ) !IdChar ;

////////// Characters

Identifier = !Keyword a:IdNondigit b:IdChar* ws {return a + b.join('')} ;

Digit      = [0-9] ;
HexDigit   = [0-9] / [a-f] / [A-F] ;
IdChar     = [a-z] / [A-Z] / [0-9] / [_] / UniversalCharacter ;
IdNondigit = [a-z] / [A-Z]         / [_] / UniversalCharacter ;

UniversalCharacter = "\\u" HexQuad / "\\U" HexQuad HexQuad ;

HexQuad = HexDigit HexDigit HexDigit HexDigit ;


//////////  Punctuators

LBRK       =  a:"["         ws {return a;};
RBRK       =  a:"]"         ws {return a;};
LPAR       =  a:"("         ws {return a;};
RPAR       =  a:")"         ws {return a;};
LWING      =  a:"{"         ws {return a;};
RWING      =  a:"}"         ws {return a;};
DOT        =  a:"."         ws {return a;};
PTR        =  a:"->"        ws {return a;};
INC        =  a:"++"        ws {return a;};
DEC        =  a:"--"        ws {return a;};
AND        =  a:"&"  ![&]   ws {return a;};
STAR       =  a:"*"  ![=]   ws {return a;};
PLUS       =  a:"+"  ![+=]  ws {return a;};
MINUS      =  a:"-"  ![\-=>]ws {return a;};
TILDA      =  a:"~"         ws {return a;};
BANG       =  a:"!"  ![=]   ws {return a;};
DIV        =  a:"/"  ![=]   ws {return a;};
MOD        =  a:"%"  ![=>]  ws {return a;};
LEFT       =  a:"<<" ![=]   ws {return a;};
RIGHT      =  a:">>" ![=]   ws {return a;};
LT         =  a:"<"  ![=]   ws {return a;};
GT         =  a:">"  ![=]   ws {return a;};
LE         =  a:"<="        ws {return a;};
GE         =  a:">="        ws {return a;};
EQUEQU     =  a:"=="        ws {return a;};
BANGEQU    =  a:"!="        ws {return a;};
HAT        =  a:"^"  ![=]   ws {return a;};
OR         =  a:"|"  ![=]   ws {return a;};
ANDAND     =  a:"&&"        ws {return a;};
OROR       =  a:"||"        ws {return a;};
QUERY      =  a:"?"         ws {return a;};
COLON      =  a:":"  ![>]   ws {return a;};
SEMI       =  a:";"         ws {return a;};
ELLIPSIS   =  a:"..."       ws {return a;};
EQU        =  a:"="  !"="   ws {return a;};
STAREQU    =  a:"*="        ws {return a;};
DIVEQU     =  a:"/="        ws {return a;};
MODEQU     =  a:"%="        ws {return a;};
PLUSEQU    =  a:"+="        ws {return a;};
MINUSEQU   =  a:"-="        ws {return a;};
LEFTEQU    =  a:"<<="       ws {return a;};
RIGHTEQU   =  a:">>="       ws {return a;};
ANDEQU     =  a:"&="        ws {return a;};
HATEQU     =  a:"^="        ws {return a;};
OREQU      =  a:"|="        ws {return a;};
COMMA      =  a:","         ws {return a;};
SCOPEOP    =  a:"::"        ws {return a;};

////////// ws and comments

ws = (WhiteSpace)* ;

WhiteSpace  = a:[ \n\r\t\u000B\u000C] {return a;};
