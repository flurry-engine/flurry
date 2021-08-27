package uk.aidanlee.flurry.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

class Host
{
    /**
     * https://community.haxe.org/t/initialize-class-instance-from-expr-in-macro/521
     */
    public static macro function entry(_events, _mainScheduler, _taskScheduler) : ExprOf<Flurry>
    {
        if (!Context.defined('flurry-entry-point'))
        {
            Context.error('flurry entry point not defined', Context.currentPos());
        }

        if (Context.defined('flurry-cppia'))
        {
            final scriptPath  = Context.definedValue('flurry-cppia-script');
            final scriptClass = Context.definedValue('flurry-entry-point');

            return macro {
                final module = cpp.cppia.Module.fromData(sys.io.File.getBytes($v{ scriptPath }).getData());
                module.boot();

                Type.createInstance(module.resolveClass($v{ scriptClass }), [ $e{ _events }, $e{ _mainScheduler }, $e{ _taskScheduler } ]);
            }
        }
        else
        {
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

                            macro new $path($e{ _events }, $e{ _mainScheduler }, $e{ _taskScheduler });
                        default:
                            Context.error('Entry point must be a class path', Context.currentPos());
                    }
                default:
                    Context.error('Entry point must be constant', Context.currentPos());
            }
        }
    }
}