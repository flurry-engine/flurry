package tests.api.io;

import haxe.io.Bytes;
import sys.io.abstractions.mock.MockFileSystem;
import uk.aidanlee.flurry.FlurryConfig.FlurryProjectConfig;
import uk.aidanlee.flurry.api.io.FileSystemIO;
import haxe.io.Path;
import buddy.BuddySuite;

using buddy.Should;

class FileSystemIOTests extends BuddySuite
{
    public function new()
    {
        describe('FileSystemIO', {
            final project     = new FlurryProjectConfig();
            final fs          = new MockFileSystem([], []);
            final preferences = new FileSystemIO(project, fs);
            final configDir = switch Sys.systemName()
            {
                case 'Windows' : Path.join([ Sys.getEnv('APPDATA'), project.author, project.name ]);
                case 'Mac'     : Path.join([ Sys.getEnv('HOME'), 'Library', 'Application Support', project.author, project.name ]);
                case 'Linux'   : Path.join([ Sys.getEnv('XDG_DATA_HOME'), project.author, project.name ]);
                case _: '';
            }

            describe('fetching the preference path', {
                it('will ensure the preference path directory exists', {
                    preferences.preferencePath();
                    fs.directory.exist(configDir).should.be(true);
                });

                it('can provide the folder it is saving the preferences in', {
                    preferences.preferencePath().should.be(configDir);
                });
            });

            it('can check if a preference exists', {
                fs.file.writeText(Path.join([ configDir, 'key_1' ]), '');

                preferences.has('key_1').should.be(true);
                preferences.has('key_2').should.be(false);
            });

            it('can remove a preference', {
                fs.file.exists(Path.join([ configDir, 'key_1' ])).should.be(true);
                preferences.remove('key_1');
                fs.file.exists(Path.join([ configDir, 'key_1' ])).should.be(false);
            });

            describe('getting preference strings', {
                it('will return the preference as a string if it exists', {
                    fs.file.writeText(Path.join([ configDir, 'key_1' ]), 'Hello World!');

                    switch preferences.getString('key_1')
                    {
                        case Some(v): v.should.be('Hello World!');
                        case None: fail('expected some string');
                    }
                });
                it('will return None if the preference does not exist', {
                    switch preferences.getString('key_2')
                    {
                        case Some(_): fail('did not expect a value');
                        case None: //
                    }
                });
            });

            describe('getting preference bytes', {
                it('will return the preference as bytes if it exists', {
                    fs.file.writeText(Path.join([ configDir, 'key_1' ]), 'Hello World!');

                    switch preferences.getBytes('key_1')
                    {
                        case Some(v): v.toString().should.be('Hello World!');
                        case None: fail('expected some string');
                    }
                });
                it('will return None if the preference does not exist', {
                    switch preferences.getBytes('key_2')
                    {
                        case Some(_): fail('did not expect a value');
                        case None: //
                    }
                });
            });

            describe('writing preferences', {
                fs.file.writeText(Path.join([ configDir, 'key_1' ]), 'Hello World!');

                it('will overwrite an existing value when writing a string', {
                    preferences.setString('key_1', 'Hello String!');
                    fs.file.getText(Path.join([ configDir, 'key_1' ])).should.be('Hello String!');
                });
                it('will overwrite an existing value when writing bytes', {
                    preferences.setBytes('key_1', Bytes.ofString('Hello Bytes!'));
                    fs.file.getText(Path.join([ configDir, 'key_1' ])).should.be('Hello Bytes!');
                });
            });
        });
    }
}