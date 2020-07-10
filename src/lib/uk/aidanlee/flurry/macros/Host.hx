package uk.aidanlee.flurry.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

class Host
{
    /**
     * https://community.haxe.org/t/initialize-class-instance-from-expr-in-macro/521
     */
    public static macro function entry() : ExprOf<Flurry>
    {
        if (!Context.defined('flurry-entry-point'))
        {
            Context.error('flurry entry point not defined', Context.currentPos());
        }

        final found = macro $i{ Context.definedValue('flurry-entry-point') };

        return switch found.expr
        {
            case EConst(CIdent(cls)):
                switch Context.getType(cls)
                {
                    case TInst(_.get() => t, _):
                        var path = {
                            name : t.name,
                            sub  : t.module == t.name ? null : t.name,
                            pack : t.pack
                        };

                        macro new $path();
                    default:
                        Context.error('Entry point must be a class path', Context.currentPos());
                }
            default:
                Context.error('Entry point must be constant', Context.currentPos());
        }
    }
}