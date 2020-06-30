package tests;

import Types.Project;
import commands.Run;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;

using mockatoo.Mockatoo;
using buddy.Should;
using Utils;

class RunCommandTests extends BuddySuite
{
    public function new()
    {
        describe('Run Command', {
            it('will bubble up success results', {
                final project = project();
                final proc    = mock(Proc);
                Mockatoo.returns(proc.run(project.executable(), emptyArray()), Success(Unit.value));

                new Run(project, proc).run().should.equal(Success(Unit.value));
            });
            it('will bubble up failure results', {
                final project = project();
                final proc    = mock(Proc);
                Mockatoo.returns(proc.run(anyString, anyIterator), Failure('custom error message'));

                new Run(project, proc).run().should.equal(Failure('custom error message'));
            });
            it('will invoke the projects executable from the output directory', {
                final project = project();
                final proc    = mock(Proc);
                Mockatoo.returns(proc.run(anyString, anyIterator), Success(Unit.value));

                new Run(project, proc).run().should.equal(Success(Unit.value));

                Mockatoo.verify(proc.run(project.executable(), emptyArray()), 1);
            });
        });
    }

    function emptyArray() : Matcher
        return customMatcher(array -> array.length == 0);

    function project() : Project
        return {
            app : {
                name      : "ExecutableName",
                namespace : "com.project.namespace",
                output    : "bin",
                main      : "Main",
                codepaths : [ "src" ],
                backend   : Snow
            }
        }
}