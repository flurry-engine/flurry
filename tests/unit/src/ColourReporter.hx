
import haxe.CallStack.StackItem;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;

using StringTools;

class ColourReporter implements Reporter
{
    var reportName : String;

    var total : Int;

    var passing : Int;

    var failures : Int;

    var pending : Int;

    var unknowns : Int;

    public function new()
    {
        total      = 0;
        passing    = 0;
        failures   = 0;
        pending    = 0;
        unknowns   = 0;
    }

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
        for (suite in _suites)
        {
            countSuite(suite);
            printSuite(suite, -1);
        }

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

    function indentString(_string : String, _indentLevel : Int) : String
    {
        return _string.lpad(' ', _string.length + (_indentLevel * 2));
    }

    function countSuite(_suite : Suite)
    {
        if (_suite.error != null)
        {
            failures++;
        }

        for (step in _suite.steps)
        {
            switch (step)
            {
                case TSpec(step):
                    total++;
                    
                    switch (step.status)
                    {
                        case Unknown: unknowns++;
                        case Passed : passing++;
                        case Pending: pending++;
                        case Failed : failures++;
                    }

                case TSuite(step):
                    countSuite(step);
            }
        }
    }

    function printSuite(_suite : Suite, _baseIndent : Int)
    {
        if (_suite.description.length > 0)
        {
            Log.print(indentString(_suite.description, _baseIndent), Log.ansiColours['yellow']);
        }

        if (_suite.error != null)
        {
            Log.error(indentString('ERROR: ${_suite.error}', _baseIndent));

            printStack(_suite.stack, _baseIndent + 2);

            return;
        }

        for (spec in _suite.specs)
        {
            printSpec(spec, _baseIndent + 1);
        }

        for (suite in _suite.suites)
        {
            printSuite(suite, _baseIndent + 1);
        }
    }

    function printSpec(_spec : Spec, _baseIndent : Int)
    {
        switch (_spec.status)
        {
            case Unknown: Log.print(indentString('[UNKN] ' + Log.ansiColours['none'] + _spec.description, _baseIndent), Log.ansiColours['grey' ]);
            case Passed : Log.print(indentString('[PASS] ' + Log.ansiColours['none'] + _spec.description, _baseIndent), Log.ansiColours['green']);
            case Pending: Log.print(indentString('[PEND] ' + Log.ansiColours['none'] + _spec.description, _baseIndent), Log.ansiColours['yellow']);
            case Failed :
                Log.error(indentString('[FAIL] ${Log.ansiColours['none']}${_spec.description}', _baseIndent));

                for (failure in _spec.failures)
                {
                    Log.print(indentString(failure.error, _baseIndent), Log.ansiColours['yellow']);

                    printStack(failure.stack, _baseIndent);
                }
        }

        for (line in _spec.traces)
        {
            Log.print(indentString(line, _baseIndent ), Log.ansiColours['yellow']);
        }
    }

    function printStack(_stack : Array<StackItem>, _baseIndent : Int)
    {
        if (_stack == null || _stack.length == 0)
        {
            return;
        }

        for (item in _stack)
        {
            switch (item)
            {
                case FilePos(s, file, line, column):
                    if (line > 0 && file.indexOf('buddy/internal/') != 0 && file.indexOf('buddy.SuitesRunner') != 0)
                    {
                        Log.print(indentString('@ $file:$line', _baseIndent + 1), Log.ansiColours['yellow']);
                    }
                default:
                    //
            }
        }
    }
}