package tests.api.resources;

import Types.Project;
import Types.Backend;
import commands.Restore;
import parcel.Packer;
import haxe.Exception;
import buddy.SingleSuite;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.schedulers.CurrentThreadScheduler;
import sys.io.abstractions.mock.MockFileSystem;
import sys.io.abstractions.mock.MockFileData;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;
using rx.Observable;

class ResourceSystemTests extends SingleSuite
{
    final parcels : Map<String, haxe.io.Bytes>;

    final project : Project;

    public function new()
    {
        parcels = [];
        project = {
            app: {
                name      : '',
                backend   : Backend.Snow,
                codepaths : [],
                main      : '',
                output    : 'bin',
                author    : ''
            },
            parcels: [ 'assets/assets.json' ]
        };

        switch new Restore(project).run()
        {
            case Success(_): //
            case Failure(message): throw new Exception('failed to download tools : $message');
        }
        switch new Packer(project, Ogl3).create('assets/assets.json')
        {
            case Success(data):
                for (parcel in data)
                {
                    parcels[parcel.name] = sys.io.File.getBytes(parcel.file);
                }
            case Failure(message): throw new Exception('failed to build parcels : $message');
        }

        describe('ResourceSystem', {

            describe('Manually Managing Resources', {
                final sys = new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final res = new TextResource('hello', 'world');
    
                it('allows manually adding resources to the system', {
                    sys.addResource(res);
                });

                it('allows fetching the resource by its name', {
                    final res = sys.getByName('hello', TextResource);
                    res.name.should.be('hello');
                    res.content.should.be('world');
                });

                it('allows fetching the resource by its ID', {
                    final id  = Hash.hash('hello');
                    final res = sys.getByID(id, TextResource);
                    res.id.should.be(id);
                    res.content.should.be('world');
                });
    
                it('allows manually removing resources from the system', {
                    sys.removeResource(res);
                    sys.getByName.bind('hello', Resource).should.throwType(ResourceNotFoundException);
                });
            });

            describe('Managing Parcels', {
                final files  = [ 'assets/parcels/images.parcel' => MockFileData.fromBytes(parcels['images.parcel']) ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);

                it('can load a pre-packaged parcels resources', {
                    system.load([ 'images.parcel' ]);
                });

                it('allows fetching the resource by its name', {
                    final res = system.getByName('dots', ImageFrameResource);
                    res.name.should.be('dots');
                    res.width.should.be(2);
                    res.height.should.be(2);
                });

                it('allows fetching the resource by its ID', {
                    final id  = Hash.hash('dots');
                    final res = system.getByID(id, ImageFrameResource);
                    res.id.should.be(id);
                    res.width.should.be(2);
                    res.height.should.be(2);
                });

                it('can remove a parcels resources from the system', {
                    system.free('images.parcel');
                    system.getByName.bind('dots', Resource).should.throwType(ResourceNotFoundException);
                });
            });

            describe('Resource Events', {
                final events = new ResourceEvents();
                final system = new ResourceSystem(events, new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final image  = new ImageResource('dots', 2, 2, RGBAUNorm, haxe.io.Bytes.alloc(2 * 2 * 4).getData());
                final shader = new ShaderResource(
                    'shdr',
                    haxe.io.Bytes.ofString('vertex'),
                    haxe.io.Bytes.ofString('fragment'),
                    new ShaderVertInfo([], []),
                    new ShaderFragInfo([], [], []));

                it('will fire a create event when adding an image resource', {
                    final sub = events.created.subscribeFunction(ev -> {
                        switch ev.type
                        {
                            case Image:
                                final res : ImageResource = cast ev;
                                res.type.should.equal(Image);
                                res.name.should.be('dots');
                                res.width.should.be(2);
                                res.height.should.be(2);
                            case _: fail('expected image');
                        }
                    });

                    system.addResource(image);
                    sub.unsubscribe();
                });

                it('will fire a create event when adding a shader resource', {
                    final sub = events.created.subscribeFunction(ev -> {
                        switch ev.type
                        {
                            case Shader:
                                final res : ShaderResource = cast ev;
                                res.name.should.be('shdr');
                                res.vertSource.toString().should.be('vertex');
                                res.fragSource.toString().should.be('fragment');
                            case _: fail('expected shader');
                        }
                    });

                    system.addResource(image);
                    sub.unsubscribe();
                });

                it('will fire a remove event when removing an image resource', {
                    final sub = events.removed.subscribeFunction(ev -> {
                        switch ev.type
                        {
                            case Image:
                                final res : ImageResource = cast ev;
                                res.type.should.equal(Image);
                                res.name.should.be('dots');
                                res.width.should.be(2);
                                res.height.should.be(2);
                            case _: fail('expected image');
                        }
                    });

                    system.removeResource(shader);
                    sub.unsubscribe();
                });

                it('will fire a remove event when removing a shader resource', {
                    final sub = events.removed.subscribeFunction(ev -> {
                        switch ev.type
                        {
                            case Shader:
                                final res : ShaderResource = cast ev;
                                res.name.should.be('shdr');
                                res.vertSource.toString().should.be('vertex');
                                res.fragSource.toString().should.be('fragment');
                            case _: fail('expected shader');
                        }
                    });

                    system.removeResource(shader);
                    sub.unsubscribe();
                });
            });

            describe('Resource Reference Counting', {
                final files = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(parcels['images.parcel']),
                    'assets/parcels/moreImages.parcel' => MockFileData.fromBytes(parcels['moreImages.parcel'])
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);

                it('can load parcels which contain the same resources', {
                    system.load([ 'images.parcel', 'moreImages.parcel' ]);
                });

                it('will not remove a resource if there are multiple references', {
                    system.free('images.parcel');

                    final res = system.getByName('dots', ImageFrameResource);
                    res.name.should.be('dots');
                    res.width.should.be(2);
                    res.height.should.be(2);

                    final id  = Hash.hash('dots');
                    final res = system.getByID(id, ImageFrameResource);
                    res.id.should.be(id);
                    res.width.should.be(2);
                    res.height.should.be(2);
                });

                it('will remove the resources once all references have been lost', {
                    system.free('moreImages.parcel');
                    system.getByName.bind('dots', Resource).should.throwType(ResourceNotFoundException);
                    system.getByID.bind(Hash.hash('dots'), Resource).should.throwType(ResourceNotFoundException);
                });
            });

            it('will return an empty observable when trying to load an already loaded parcel', {
                var calls = 0;

                final files = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(parcels['images.parcel']),
                    'assets/parcels/preload.parcel' => MockFileData.fromBytes(parcels['preload.parcel'])
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final parcel = 'preload.parcel';

                system.load([ parcel ]);
                system.load([ parcel ]).subscribeFunction(() -> calls++);

                calls.should.be(1);
            });

            it('will thrown an exception when trying to get a resource as the wrong type', {
                final files  = [ 'assets/parcels/images.parcel' => MockFileData.fromBytes(parcels['images.parcel']) ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                
                system.load([ 'images.parcel' ]);

                // This try catch is needed for hashlink.
                // if we try and bind and use buddys exception catching we get a compile error about not knowing how to cast.
                try
                {
                    system.getByName('dots', BytesResource);
                }
                catch (e : Exception)
                {
                    e.should.beType(InvalidResourceTypeException);
                }
            });

            it('contains a callback for when the parcel has finished loading', {
                var result = '';

                final files = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(parcels['images.parcel'])
                ];
                new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current)
                    .load([ 'images.parcel' ])
                    .subscribeFunction(() -> result = 'finished');

                result.should.be('finished');
            });

            it('contains a callback for when the parcel has failed to load', {
                var result = '';
                new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current)
                    .load([ 'myParcel' ])
                    .subscribeFunction((_error : String) -> result = 'error');

                result.should.be('error');
            });
        });
    }
}
