package igloo.logger;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.MacroStringTools;
import igloo.logger.LogLevel;

class Log implements ISink
{
    final enrichers : Array<Enrichment>;

    final sinks : Array<ISink>;

    final level : LogLevel;

    public function new(_enrichers, _sinks, _level)
    {
        enrichers = _enrichers;
        sinks     = _sinks;
        level     = _level;
    }

    public macro function verbose(_this : Expr, _template : ExprOf<String>, _args : Array<Expr>)
    {
        return switch _template.expr
        {
            case EConst(CString(s, _)):
                final expanded = MacroStringTools.formatString(s, _template.pos);
                final level    = macro igloo.logger.LogLevel.Verbose;

                switch _args.length
                {
                    case 0:
                        LogTools.makeLogLiteralMessage(_this, level, _template, expanded);
                    case _:
                        LogTools.makeLogRestMessage(_this, level, expanded, _args);
                }
            case _:
                Context.error('Log template must be a string literal', Context.currentPos());
        }
    }

    public macro function debug(_this : Expr, _template : ExprOf<String>, _args : Array<Expr>)
    {
        return switch _template.expr
        {
            case EConst(CString(s, _)):
                final expanded = MacroStringTools.formatString(s, _template.pos);
                final level    = macro igloo.logger.LogLevel.Debug;

                switch _args.length
                {
                    case 0:
                        LogTools.makeLogLiteralMessage(_this, level, _template, expanded);
                    case _:
                        LogTools.makeLogRestMessage(_this, level, expanded, _args);
                }
            case _:
                Context.error('Log template must be a string literal', Context.currentPos());
        }
    }

    public macro function info(_this : Expr, _template : ExprOf<String>, _args : Array<Expr>)
    {
        return switch _template.expr
        {
            case EConst(CString(s, _)):
                final expanded = MacroStringTools.formatString(s, _template.pos);
                final level    = macro igloo.logger.LogLevel.Information;

                switch _args.length
                {
                    case 0:
                        LogTools.makeLogLiteralMessage(_this, level, _template, expanded);
                    case _:
                        LogTools.makeLogRestMessage(_this, level, expanded, _args);
                }
            case _:
                Context.error('Log template must be a string literal', Context.currentPos());
        }
    }

    public macro function warning(_this : Expr, _template : ExprOf<String>, _args : Array<Expr>)
    {
        return switch _template.expr
        {
            case EConst(CString(s, _)):
                final expanded = MacroStringTools.formatString(s, _template.pos);
                final level    = macro igloo.logger.LogLevel.Warning;

                switch _args.length
                {
                    case 0:
                        LogTools.makeLogLiteralMessage(_this, level, _template, expanded);
                    case _:
                        LogTools.makeLogRestMessage(_this, level, expanded, _args);
                }
            case _:
                Context.error('Log template must be a string literal', Context.currentPos());
        }
    }

    public macro function error(_this : Expr, _template : ExprOf<String>, _args : Array<Expr>)
    {
        return switch _template.expr
        {
            case EConst(CString(s, _)):
                final expanded = MacroStringTools.formatString(s, _template.pos);
                final level    = macro igloo.logger.LogLevel.Error;

                switch _args.length
                {
                    case 0:
                        LogTools.makeLogLiteralMessage(_this, level, _template, expanded);
                    case _:
                        LogTools.makeLogRestMessage(_this, level, expanded, _args);
                }
            case _:
                Context.error('Log template must be a string literal', Context.currentPos());
        }
    }

    public function onMessage(_message : Message.Message)
    {
        if (_message.level < getLevel())
        {
            return;
        }

        for (enricher in enrichers)
        {
            _message.setField(enricher.field, enricher.value);
        }

        for (sink in sinks)
        {
            if (_message.level < sink.getLevel())
            {
                continue;
            }

            sink.onMessage(_message);
        }
    }

    public function getLevel() {
        return level;
    }
}