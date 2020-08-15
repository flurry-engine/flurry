package tests;

import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;
import Types.Project;
import commands.Build;
import parcel.Packer;
import haxe.io.Path;
import haxe.io.Bytes;
import sys.io.abstractions.mock.MockFileData;
import sys.io.abstractions.mock.MockFileSystem;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using mockatoo.Mockatoo;
using buddy.Should;
using StringTools;
using Utils;

class BuildCommandTests extends BuddySuite
{
    public function new()
    {
        describe('Build Command', {
            describe('successfully building a project', {
                final path    = '/path/to/build/file.json';
                final project = project();
                final fs      = new MockFileSystem([
                    'some/random/directory/native_lib1.so' => MockFileData.fromText(''),
                    'some/random/directory/native_lib2.so' => MockFileData.fromText(''),
                    'some/random/directory/native_static.a' => MockFileData.fromText(''),
                    'bin/windows.build/cpp/SDLHost-debug.exe' => MockFileData.fromText(''),
                    'bin/temp/parcel/parcel1' => MockFileData.fromText('hello'),
                    'bin/temp/parcel/parcel2' => MockFileData.fromText('world'),
                ], []);
                final packer  = mock(Packer);
                final proc    = mock(Proc);
    
                Mockatoo.returns(proc.run(), Success(Unit.value));
                Mockatoo.returns(packer.create(), Success([
                    { name : 'parcel1', file : 'bin/temp/parcel/parcel1' },
                    { name : 'parcel2', file : 'bin/temp/parcel/parcel2' }
                ]));
    
                final result = new Build(project, false, false, path, 'mock', fs, packer, proc).run();
    
                it('will can build the project', {
                    result.should.equal(Success(Unit.value));
                });
                it('will create a build.hxml file', {
                    fs.file.exists('bin/windows.build/build.hxml').should.be(true);
                });
                it('will set the flurry entry point define in the build.hxml', {      
                    fs.file.getText('bin/windows.build/build.hxml').contains('-D flurry-entry-point=${ project.app.main }').should.be(true);
                });
                it('will set the flurry build file define in the build.hxml', {                   
                    fs.file.getText('bin/windows.build/build.hxml').contains('-D flurry-build-file=${ path }').should.be(true);
                });
                it('will set the entry point to be SDLHost in the build.hxml', {
                    fs.file.getText('bin/windows.build/build.hxml').contains('-m uk.aidanlee.flurry.hosts.SDLHost').should.be(true);
                });
                it('will add all project codepaths to the build.hxml', {   
                    final text = fs.file.getText('bin/windows.build/build.hxml');
    
                    for (p in project.app.codepaths)
                    {
                        text.contains('-p $p');
                    }
                });
                it('will add all project macros to the build.hxml', {
                    final text = fs.file.getText('bin/windows.build/build.hxml');
    
                    for (m in project.build.macros)
                    {
                        text.contains('--macro $m').should.be(true);
                    }
                });
                it('will add all project dependencies to the build.hxml', {    
                    final text = fs.file.getText('bin/windows.build/build.hxml');
    
                    for (d in project.build.dependencies)
                    {
                        final lib = if (d.version == null) '-lib ${ d.lib }' else '-lib ${ d.lib }:${ d.version }';
    
                        text.contains(lib).should.be(true);
                    }
                });
                it('will add all project defines to the build.hxml', {    
                    final text = fs.file.getText('bin/windows.build/build.hxml');
    
                    for (d in project.build.defines)
                    {
                        final def = if (d.value == null) '-D ${ d.def }' else '-D ${ d.def }=${ d.value }';
    
                        text.contains(def).should.be(true);
                    }
                });
                it('will invoke haxe with the build.hxml file', {
                    Mockatoo.verify(proc.run('npx', customMatcher(obj -> {
                        if (obj.length == 2)
                        {
                            final array = (cast obj : Array<String>);
    
                            return array[0] == 'haxe' && array[1] == Path.join([ Utils.buildPath(project), 'build.hxml' ]);
                        }
                        else
                        {
                            return false;
                        }
                    })), 1);
                });
                it('will pass the location of each asset bundle to the packer', {
                    Mockatoo.verify(packer.create('path/to/assets.json'), 1);
                });
                it('will write the parcel bytes to the build and release parcel folder', {
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'assets', 'parcels', 'parcel1' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'assets', 'parcels', 'parcel2' ])).should.be(true);
    
                    fs.file.exists(Path.join([ Utils.releasePath(project), 'assets', 'parcels', 'parcel1' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.releasePath(project), 'assets', 'parcels', 'parcel2' ])).should.be(true);
    
                    fs.file.getBytes(Path.join([ Utils.buildPath(project), 'cpp', 'assets', 'parcels', 'parcel1' ])).compare(Bytes.ofString('hello')).should.be(0);
                    fs.file.getBytes(Path.join([ Utils.buildPath(project), 'cpp', 'assets', 'parcels', 'parcel2' ])).compare(Bytes.ofString('world')).should.be(0);
    
                    fs.file.getBytes(Path.join([ Utils.releasePath(project), 'assets', 'parcels', 'parcel1' ])).compare(Bytes.ofString('hello')).should.be(0);
                    fs.file.getBytes(Path.join([ Utils.releasePath(project), 'assets', 'parcels', 'parcel2' ])).compare(Bytes.ofString('world')).should.be(0);
                });
                it('will not rename the output executable in the build directory', {
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'SDLHost-debug.exe' ])).should.be(true);
                });
                it('will copy the executable to the release folder with the project name', {
                    fs.files.exists(Path.join([ Utils.releasePath(project), '${ project.app.name }.exe' ])).should.be(true);
                });
                it('will have copied any files matched by the glob into the directory relative to the build directory executable', {
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'native_lib1.so' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'native_lib2.so' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.buildPath(project), 'cpp', 'native_static.a' ])).should.be(false);
                });
                it('will have copied any files matched by the glob into the directory relative to the release directory executable', {
                    fs.file.exists(Path.join([ Utils.releasePath(project), 'native_lib1.so' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.releasePath(project), 'native_lib2.so' ])).should.be(true);
                    fs.file.exists(Path.join([ Utils.releasePath(project), 'native_static.a' ])).should.be(false);
                });
            });
        });
    }

    function project() : Project
        return {
            app : {
                name      : "ExecutableName",
                author    : "flurry",
                output    : "bin",
                main      : "Main",
                codepaths : [ "src" ],
                backend   : Sdl
            },
            build : {
                defines : [
                    { def : 'custom_define' },
                    { def : 'custom_define_with_value', value : 'value' }
                ],
                dependencies : [
                    { lib : 'custom_lib' },
                    { lib : 'custom_lib_with_version', version : 'v1.2.3' }
                ],
                macros: [ 'MyMacro.someFunc()' ],
                files: [ 'some/random/directory/native_*.so' => '' ]
            },
            parcels : [ 'path/to/assets.json' ]
        }
}