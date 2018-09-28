package;

import haxe.CallStack.StackItem;
import buddy.reporting.Reporter;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import promhx.Deferred;
import promhx.Promise;

using StringTools;
using Lambda;

class ColorReporter implements Reporter
{
    public function new() {}

    public function start() : Promise<Bool>
    {
        return resolve(true);
    }

    public function progress(_spec : Spec) : Promise<Spec>
    {
        return resolve(_spec);
    }

    public function done(_suites : Iterable<Suite>, _status : Bool) : Promise<Iterable<Suite>>
    {
        var total    = 0;
        var failures = 0;
        var pending  = 0;

        var countTests : Suite -> Void = null;
        var printTests : Suite -> Int -> Void = null;

        countTests = function(_s : Suite) {
            if (_s.error != null) failures++;

            for (sp in _s.steps)
            {
                switch (sp)
                {
                    case TSpec(sp):
                        total++;
                        if (sp.status == Failed)
                        {
                            failures++;
                        }
                        else if (sp.status == Pending)
                        {
                            pending++;
                        }

                    case TSuite(_s):
                        countTests(_s);
                }
            }
        };

        printTests = function(_s : Suite, _indentLevel : Int) {

            /**
             * Pads the provided string according to the indent level of the test.
             * @param _str String to pad.
             * @return String
             */
            function padTest(_str : String) : String {
                return _str.lpad(' ', _str.length + Std.int(Math.max(0, _indentLevel * 2)));
            }

            /**
             * Logs the stack to the output.
             * @param _indent Current indent level.
             * @param _stack  Stack to print.
             */
            function logStack(_indent : String, _stack : Array<StackItem>) {
                if (_stack == null || _stack.length == 0) return;
                for (s in _stack) switch(s)
                {
                    case FilePos(_, file, line) if (line > 0 && file.indexOf('buddy/internal/') != 0 && file.indexOf('buddy.SuitesRunner') != 0):
                        Log.print(padTest(_indent + '@ $file:$line'), Log.ansiColours['yellow']);
                    case _:
                        //
                }
            }

            /**
             * [Description]
             * @param _spec - 
             */
            function logTraces(_spec : Spec) {
                for (t in _spec.traces) Log.print(padTest('    ' + t), Log.ansiColours['yellow']);
            }

            if (_s.description.length > 0) Log.print(padTest(_s.description), Log.ansiColours['yellow']);
            if (_s.error != null)
            {
                Log.error(padTest('ERROR: ' + _s.error));
                logStack('    ', _s.stack);
                return;
            }

            // Print the actual test results.
            for (step in _s.steps) switch step
            {
                case TSpec(sp):
                    if (sp.status == Failed)
                    {
                        Log.error(padTest('[FAIL] ' + Log.ansiColours['none'] + sp.description));
                        for (failure in sp.failures)
                        {
                            Log.print(padTest('    ' + failure.error), Log.ansiColours['yellow']);
                            logStack('    ', failure.stack);
                        }
                    }
                    else
                    {
                        switch (sp.status)
                        {
                            case Passed  : Log.print(padTest('[PASS] ' + Log.ansiColours['none'] + sp.description), Log.ansiColours['green' ]);
                            case Pending : Log.print(padTest('[PEND] ' + Log.ansiColours['none'] + sp.description), Log.ansiColours['yellow']);
                            case _       : Log.print(padTest('[UNKN] ' + Log.ansiColours['none'] + sp.description), Log.ansiColours['grey'  ]);
                        }
                    }
                    logTraces(sp);
                case TSuite(s):
                    printTests(s, _indentLevel + 1);
            }
        };

        _suites.iter(countTests);
        _suites.iter(printTests.bind(_, -1));

        Log.print('[PASS] ' + Log.ansiColours['none'] + '${total - pending - failures} passing tests'  , Log.ansiColours['green' ]);
        Log.print('[PEND] ' + Log.ansiColours['none'] + '$pending pending tests', Log.ansiColours['yellow']);
        Log.print('[FAIL] ' + Log.ansiColours['none'] + '$failures failing tests', Log.ansiColours['red'   ]);

        return resolve(_suites);
    }

    function resolve<T>(_o : T) : Promise<T>
    {
        var def = new Deferred<T>();
        var prm = def.promise();

        def.resolve(_o);
        return prm;
    }
}