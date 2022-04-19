package igloo.logger;

import haxe.macro.Expr;
import haxe.macro.ExprTools;

function makeLogLiteralMessage(_this : Expr, _level : Expr, _message : Expr, _formatted : Expr) {
    final fields = [
        ({ field : 'message', expr : _message } : ObjectField),
        ({ field : 'timestamp', expr : macro Date.now().toString() } : ObjectField),
        ({ field : 'level', expr : _level } : ObjectField)
    ];

    ExprTools.iter(_formatted, find_consts.bind(fields));

    return macro $e{ _this }.onMessage(cast $e{ { expr : EObjectDecl(fields), pos : _message.pos } });
}

function makeLogRestMessage(_this : Expr, _level : Expr, _formatted : Expr, _args : Array<Expr>) {
    final fields     = new Array<ObjectField>();
    final mapperArgs = { idx : 0, args : _args, fields : fields };
    final message    = mapper(mapperArgs, _formatted);

    fields.push({ field : 'timestamp', expr : macro Date.now().toString() });
    fields.push({ field : 'level', expr : _level });
    fields.push({ field : 'message', expr : message });

    return macro $e{ _this }.onMessage(cast $e{ { expr : EObjectDecl(fields), pos : _formatted.pos } });
}

function find_consts(_fields : Array<ObjectField>, _e : Expr) {
    switch _e.expr {
        case EConst(CIdent(i)):
            _fields.push({ field: i, expr: _e });
        case _:
            ExprTools.iter(_e, find_consts.bind(_fields));
    }
}

function mapper(_to : { idx : Int, args : Array<Expr>, fields : Array<ObjectField> }, _e : Expr) {
    return switch _e.expr {
        case EConst(CIdent(i)):
            _to.fields.push({ field: i, expr: _to.args[_to.idx] });
            _to.args[_to.idx++];
        case _:
            ExprTools.map(_e, mapper.bind(_to));
    }
}