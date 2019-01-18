
import sys.io.File;
import haxe.CallStack.StackItem;
import buddy.BuddySuite.Spec;
import buddy.BuddySuite.Suite;
import buddy.reporting.Reporter;
import promhx.Deferred;
import promhx.Promise;

using StringTools;

class ColorReporter implements Reporter
{
    var reportName : String;
    
    var total : Int;

    var passing : Int;

    var failures : Int;

    var pending : Int;

    var unknowns : Int;

    var xml : Xml;

    var startTime : Float;

    var endTime : Float;

    public function new()
    {
        if (!isDefined('report-name'))
        {
            throw 'report-name not defined';
        }

        reportName = getDefine('report-name');
        total      = 0;
        passing    = 0;
        failures   = 0;
        pending    = 0;
        unknowns   = 0;
        xml        = Xml.createElement('assemblies');
        xml.set('timestamp', '${getDate()} ${getTime()}');
    }

    static macro function isDefined(key : String) : haxe.macro.Expr
    {
        return macro $v{haxe.macro.Context.defined(key)};
    }

    static macro function getDefine(key : String) : haxe.macro.Expr
    {
        return macro $v{haxe.macro.Context.definedValue(key)};
    }

    public function start() : Promise<Bool>
    {
        startTime = Sys.time();

        return resolve(true);
    }

    public function progress(_spec : Spec) : Promise<Spec>
    {
        return resolve(_spec);
    }

    public function done(_suites : Iterable<Suite>, _status : Bool) : Promise<Iterable<Suite>>
    {
        endTime = Sys.time();

        for (suite in _suites)
        {
            countSuite(suite);
            printSuite(suite, -1);
        }

        createReport(_suites);

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

    function createReport(_suites : Iterable<Suite>)
    {
        var assembly = Xml.createElement('assembly');
        assembly.set('name'          , 'Main.hx');
        assembly.set('config-file'   , 'build-cpp.hxml');
        assembly.set('test-framework', 'Buddy');
        assembly.set('environment', '');
        assembly.set('run-date', getDate());
        assembly.set('run-time', getTime());
        assembly.set('time'    , Std.string(endTime - startTime));
        assembly.set('total'   , Std.string(total));
        assembly.set('passed'  , Std.string(passing));
        assembly.set('failed'  , Std.string(failures));
        assembly.set('skipped' , Std.string(pending));
        assembly.set('errors'  , Std.string(0));

        var errors = Xml.createElement('errors');

        var collection = Xml.createElement('collection');
        collection.set('name'    , reportName);
        collection.set('time'    , Std.string(endTime - startTime));
        collection.set('total'   , Std.string(total));
        collection.set('passed'  , Std.string(passing));
        collection.set('failed'  , Std.string(failures));
        collection.set('skipped' , Std.string(pending));

        for (suite in _suites)
        {
            reportSuite(suite, collection);
        }

        assembly.addChild(errors);
        assembly.addChild(collection);
        xml.addChild(assembly);

        var outxml = '<?xml version="1.0" encoding="utf-8"?>\r\n' + xml.toString();

        File.saveContent('test-engine.xml', outxml);
    }

    function reportSuite(_suite : Suite, _collection : Xml)
    {
        for (spec in _suite.specs)
        {
            if (spec.status == Unknown)
            {
                continue;
            }

            var test = Xml.createElement('test');
            test.set('name', spec.description);
            test.set('type', spec.fileName);
            test.set('method', spec.description);
            test.set('time', '0.1');

            switch (spec.status)
            {
                case Passed:
                    test.set('result', 'Pass');
                case Pending:
                    test.set('result', 'Skip');

                    var reason = Xml.createElement('reason');
                    reason.addChild(Xml.createCData('Pending Test'));

                    test.addChild(reason);
                case Failed:
                    test.set('result', 'Fail');
                    for (failure in spec.failures)
                    {
                        var failureElem = Xml.createElement('failure');
                        failureElem.set('exception-type', '');
                        
                        var message = Xml.createElement('message');
                        message.addChild(Xml.createCData(failure.error));

                        var stacktrace = Xml.createElement('stack-track');
                        stacktrace.addChild(Xml.createCData(formatStackTrace(failure.stack)));

                        failureElem.addChild(message);
                        failureElem.addChild(stacktrace);

                        test.addChild(failureElem);
                    }
                case Unknown:
                    //
            }

            _collection.addChild(test);
        }

        for (suite in _suite.suites)
        {
            reportSuite(suite, _collection);
        }
    }

    function formatStackTrace(_stack : Array<StackItem>) : String
    {
        var buffer = new StringBuf();

        for (item in _stack)
        {
            switch (item) {
                case FilePos(s, file, line, column):
                    if (line > 0 && file.indexOf('buddy/internal/') != 0 && file.indexOf('buddy.SuitesRunner') != 0)
                    {
                        buffer.add('@ $file:$line\n');
                    }
                default:
                    //
            }
        }

        return buffer.toString();
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

    function getDate() : String
    {
        return '${Std.string(Date.now().getFullYear()).lpad('0', 2)}/${Std.string(Date.now().getMonth() + 1).lpad('0', 2)}/${Std.string(Date.now().getDate()).lpad('0', 2)}';
    }

    function getTime() : String
    {
        return '${Std.string(Date.now().getHours()).lpad('0', 2)}/${Std.string(Date.now().getMinutes()).lpad('0', 2)}/${Std.string(Date.now().getSeconds()).lpad('0', 2)}';
    }
}