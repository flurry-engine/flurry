package tests;

import Types.Unit;
import Types.Result;
import sys.io.abstractions.mock.MockFileSystem;
import commands.Create;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using mockatoo.Mockatoo;
using buddy.Should;
using StringTools;
using Utils;

class CreateCommandTests extends BuddySuite
{
    public function new()
    {
        describe('Create Command', {
            final fs  = new MockFileSystem([], []);
            final res = new Create(fs).run();

            it('will add a build.json file in the current directory', {
                res.should.equal(Success(Unit.value));
                fs.file.exists('build.json').should.be(true);
            });

            it('will add a Main.hx file in the src directory', {
                res.should.equal(Success(Unit.value));
                fs.directory.exist('src').should.be(true);
                fs.file.exists('src/Main.hx').should.be(true);
            });

            it('will add a assets.json file in the assets directory', {
                res.should.equal(Success(Unit.value));
                fs.directory.exist('assets').should.be(true);
                fs.file.exists('assets/assets.json').should.be(true);
            });
        });
    }
}