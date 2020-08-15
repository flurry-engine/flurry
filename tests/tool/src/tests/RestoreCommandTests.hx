package tests;

import Types.Project;
import haxe.io.Bytes;
import sys.io.abstractions.mock.MockFileSystem;
import commands.Restore;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;

using mockatoo.Mockatoo;
using buddy.Should;
using Utils;

class RestoreCommandTests extends BuddySuite
{
    public function new()
    {
        describe('Restore Command', {
            final fs      = new MockFileSystem([], []);
            final net     = mock(Net);
            final proc    = mock(Proc);
            final project = project();

            Mockatoo.returns(proc.run(), Success(Unit.value));
            Mockatoo.returns(net.download('https://github.com/flurry-engine/atlas-creator/releases/download/CI/windows-latest.tar.gz'), Success(haxe.Resource.getBytes('tgz_data')));
            Mockatoo.returns(net.download('https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/windows-latest.tar.gz'), Success(haxe.Resource.getBytes('tgz_data')));
            Mockatoo.returns(net.download('https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-vs2017-64bit-b1082c10af.tar.gz'), Success(haxe.Resource.getBytes('spirv-cross')));
            Mockatoo.returns(net.download('https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-windows-x64-Release.zip'), Success(haxe.Resource.getBytes('glslangValidator')));

            final result = new Restore(project, fs, net, proc).run();

            it('will return success', {
                result.should.equal(Success(Unit.value));
            });
            it('will invoke npx to download dependencies through lix', {
                Mockatoo.verify(proc.run('npx', customMatcher(obj -> {
                    if (obj.length == 2)
                    {
                        final array = (cast obj : Array<String>);

                        return array[0] == 'lix' && array[1] == 'download';
                    }
                    else
                    {
                        return false;
                    }
                })), 1);
            });
            it('will download the msdf-atlas-gen tool', {
                Mockatoo.verify(net.download('https://github.com/flurry-engine/msdf-atlas-gen/releases/download/CI/windows-latest.tar.gz', proc), 1);
                fs.file.exists('bin/tools/windows/msdf-atlas-gen.exe').should.be(true);
                fs.file.getText('bin/tools/windows/msdf-atlas-gen.exe').should.be('hello world');
            });
            it('will download the atlas-creator tool', {
                Mockatoo.verify(net.download('https://github.com/flurry-engine/atlas-creator/releases/download/CI/windows-latest.tar.gz', proc), 1);
                fs.file.exists('bin/tools/windows/atlas-creator.exe').should.be(true);
                fs.file.getText('bin/tools/windows/atlas-creator.exe').should.be('hello world');
            });
            it('will download the glslang tool', {
                Mockatoo.verify(net.download('https://github.com/KhronosGroup/glslang/releases/download/SDK-candidate-26-Jul-2020/glslang-master-windows-x64-Release.zip', proc), 1);
                fs.file.exists('bin/tools/windows/glslangValidator.exe').should.be(true);
                fs.file.getText('bin/tools/windows/glslangValidator.exe').should.be('glslangValidator');
            });
            it('will download the spirv-cross tool', {
                Mockatoo.verify(net.download('https://github.com/KhronosGroup/SPIRV-Cross/releases/download/2020-06-29/spirv-cross-vs2017-64bit-b1082c10af.tar.gz', proc), 1);
                fs.file.exists('bin/tools/windows/spirv-cross.exe').should.be(true);
                fs.file.getText('bin/tools/windows/spirv-cross.exe').should.be('spirv-cross');
            });
        });
    }

    function project() : Project
        return {
            app : {
                name      : "ExecutableName",
                author: "flurry",
                output    : "bin",
                main      : "Main",
                codepaths : [ "src" ],
                backend   : Snow
            }
        }
}