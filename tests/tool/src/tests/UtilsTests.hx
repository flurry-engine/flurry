package tests;

import sys.io.abstractions.mock.MockFileData;
import sys.io.abstractions.mock.MockFileSystem;
import buddy.BuddySuite;

using buddy.Should;

class UtilsTests extends BuddySuite
{
    public function new()
    {
        describe('Utils tests', {
            describe('getting the substring before the first occurence of the delimeter', {
                it('will return the substring if the delimeter is found', {
                    Utils.substringBefore('hello hello', 'lo').should.be('hel');
                });
                it('will return the original string if the delimeter was not found', {
                    Utils.substringBefore('hello world', '&').should.be('hello world');
                });
            });
            describe('getting the last substring before the last occurence of a character', {
                it('will return the substring before the last occurence of a character', {
                    Utils.substringBeforeLast('hello world', 'l'.code).should.be('hello wor');
                });
                it('will return the original string if the char code was not found', {
                    Utils.substringBeforeLast('hello world', '&'.code).should.be('hello world');
                });
            });
            // describe('recursively walking a directory and returning all files', {
            //     final fs = new MockFileSystem([
            //         '/dir1/file1.txt' => MockFileData.fromText(''),
            //         '/dir1/file2.txt' => MockFileData.fromText(''),
            //         '/dir2/file3.txt' => MockFileData.fromText(''),
            //         '/dir1/dir3/file4.txt' => MockFileData.fromText(''),
            //     ], [ '/dir1', '/dir2', '/dir1/dir3' ]);
            //     final array = [];
            //     final found = Utils.walk(fs, '/dir1', array);

            //     it('will return all files in the specified directory and sub directories', {
            //         found.should.containAll([ '/dir1/file1.txt', '/dir1/file2.txt', '/dir1/dir3/file4.txt' ]);
            //         found.should.not.contain('/dir2/file3.txt');
            //     });
            //     it('will return the same array passed into the collection argument', {
            //         found.should.be(array);
            //     });
            // });
        });
    }
}