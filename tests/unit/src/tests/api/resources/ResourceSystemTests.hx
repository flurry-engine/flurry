package tests.api.resources;

import sys.io.File;
import buddy.SingleSuite;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.Parcel.ParcelType;
import uk.aidanlee.flurry.api.schedulers.CurrentThreadScheduler;
import sys.io.abstractions.mock.MockFileSystem;
import sys.io.abstractions.mock.MockFileData;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;
using rx.Observable;

class ResourceSystemTests extends SingleSuite
{
    public function new()
    {
        describe('ResourceSystem', {

            it('allows manually adding resources to the system', {
                final sys = new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final res = mock(Resource);
                res.id.returns('hello');

                sys.addResource(res);
                sys.get('hello', Resource).should.be(res);
            });

            it('allows manually removing resources from the system', {
                final sys = new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final res = mock(Resource);
                res.id.returns('hello');

                sys.addResource(res);
                sys.get('hello', Resource).should.be(res);
                sys.removeResource(res);
                sys.get.bind('hello', Resource).should.throwType(ResourceNotFoundException);
            });

            it('can load a user defined parcels resources into the system', {
                final files = [
                    '/home/user/text.txt'  => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin'  => MockFileData.fromText('hello world!'),
                    '/home/user/dots.png'  => MockFileData.fromBytes(haxe.Resource.getBytes('dots-data')),
                    '/home/user/json.json' => MockFileData.fromText(' { "hello" : "world!" } '),
                    '/home/user/shdr.json' => MockFileData.fromText(' { "textures" : [ "defaultTexture" ], "blocks" : [] } '),
                    '/home/user/ogl3_vertex.txt'   => MockFileData.fromText('ogl3_vertex'),
                    '/home/user/ogl3_fragment.txt' => MockFileData.fromText('ogl3_fragment'),
                    '/home/user/ogl4_vertex.txt'   => MockFileData.fromText('ogl4_vertex'),
                    '/home/user/ogl4_fragment.txt' => MockFileData.fromText('ogl4_fragment'),
                    '/home/user/hlsl_vertex.txt'   => MockFileData.fromText('hlsl_vertex'),
                    '/home/user/hlsl_fragment.txt' => MockFileData.fromText('hlsl_fragment')
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel', {
                    texts   : [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes   : [ { id : 'byte', path : '/home/user/byte.bin' } ],
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt', compiled : false },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt', compiled : false },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt', compiled : false }
                    } ]
                }));

                final res = system.get('text', TextResource);
                res.id.should.be('text');
                res.content.should.be('hello world!');

                final res = system.get('byte', BytesResource);
                res.id.should.be('byte');
                res.bytes.toString().should.be('hello world!');

                final res = system.get('dots', ImageResource);
                res.id.should.be('dots');
                res.width.should.be(2);
                res.height.should.be(2);

                final res = system.get('shdr', ShaderResource);
                res.id.should.be('shdr');
                res.layout.textures.should.containExactly([ 'defaultTexture' ]);
                res.layout.blocks.should.containExactly([ ]);
                res.ogl3.vertex.should.be('ogl3_vertex');
                res.ogl3.fragment.should.be('ogl3_fragment');
                res.ogl4.vertex.should.be('ogl4_vertex');
                res.ogl4.fragment.should.be('ogl4_fragment');
                res.hlsl.vertex.should.be('hlsl_vertex');
                res.hlsl.fragment.should.be('hlsl_fragment');
            });

            it('can load a pre-packaged parcels resources', {
                final files  = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(File.getBytes('bin/images.parcel'))
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(PrePackaged('images.parcel'));

                final res = system.get('dots', ImageResource);
                res.id.should.be('dots');
                res.width.should.be(2);
                res.height.should.be(2);
            });

            it('can load all the dependencies of a pre-packaged parcel', {
                final files = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(File.getBytes('bin/images.parcel')),
                    'assets/parcels/preload.parcel' => MockFileData.fromBytes(File.getBytes('bin/preload.parcel'))
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(PrePackaged('preload.parcel'));

                system.get('dots'         , ImageResource).should.beType(ImageResource);
                system.get('ubuntu'       , TextResource).should.beType(TextResource);
                system.get('cavesofgallet', TextResource).should.beType(TextResource);
            });

            it('fires events for when images and shaders are added', {
                final files = [
                    '/home/user/dots.png'  => MockFileData.fromBytes(haxe.Resource.getBytes('dots-data')),
                    '/home/user/shdr.json' => MockFileData.fromText(' { "textures" : [ "defaultTexture" ], "blocks" : [] } '),
                    '/home/user/ogl3_vertex.txt'   => MockFileData.fromText('ogl3_vertex'),
                    '/home/user/ogl3_fragment.txt' => MockFileData.fromText('ogl3_fragment'),
                    '/home/user/ogl4_vertex.txt'   => MockFileData.fromText('ogl4_vertex'),
                    '/home/user/ogl4_fragment.txt' => MockFileData.fromText('ogl4_fragment'),
                    '/home/user/hlsl_vertex.txt'   => MockFileData.fromText('hlsl_vertex'),
                    '/home/user/hlsl_fragment.txt' => MockFileData.fromText('hlsl_fragment')
                ];
                final events = new ResourceEvents();
                events.created.subscribeFunction(_created -> {
                    switch _created.type
                    {
                        case Image:
                            final res : ImageResource = cast _created;
                            res.id.should.be('dots');
                            res.width.should.be(2);
                            res.height.should.be(2);
                        case Shader:
                            final res : ShaderResource = cast _created;
                            res.id.should.be('shdr');
                            res.layout.textures.should.containExactly([ 'defaultTexture' ]);
                            res.layout.blocks.should.containExactly([ ]);
                            res.ogl3.vertex.should.be('ogl3_vertex');
                            res.ogl3.fragment.should.be('ogl3_fragment');
                            res.ogl4.vertex.should.be('ogl4_vertex');
                            res.ogl4.fragment.should.be('ogl4_fragment');
                            res.hlsl.vertex.should.be('hlsl_vertex');
                            res.hlsl.fragment.should.be('hlsl_fragment');
                        case _:
                            fail('no other resource type should have been created');
                    }
                });

                final system = new ResourceSystem(events, new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel', {
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt', compiled : false },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt', compiled : false },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt', compiled : false }
                    } ]
                }));
            });

            it('fires events for when images and shaders are removed', {
                final files = [
                    '/home/user/dots.png'  => MockFileData.fromBytes(haxe.Resource.getBytes('dots-data')),
                    '/home/user/shdr.json' => MockFileData.fromText(' { "textures" : [ "defaultTexture" ], "blocks" : [] } '),
                    '/home/user/ogl3_vertex.txt'   => MockFileData.fromText('ogl3_vertex'),
                    '/home/user/ogl3_fragment.txt' => MockFileData.fromText('ogl3_fragment'),
                    '/home/user/ogl4_vertex.txt'   => MockFileData.fromText('ogl4_vertex'),
                    '/home/user/ogl4_fragment.txt' => MockFileData.fromText('ogl4_fragment'),
                    '/home/user/hlsl_vertex.txt'   => MockFileData.fromText('hlsl_vertex'),
                    '/home/user/hlsl_fragment.txt' => MockFileData.fromText('hlsl_fragment')
                ];
                final events = new ResourceEvents();
                events.removed.subscribeFunction(_removed -> {
                    switch _removed.type
                    {
                        case Image:
                            final res : ImageResource = cast _removed;
                            res.id.should.be('dots');
                            res.width.should.be(2);
                            res.height.should.be(2);
                        case Shader:
                            final res : ShaderResource = cast _removed;
                            res.id.should.be('shdr');
                            res.layout.textures.should.containExactly([ 'defaultTexture' ]);
                            res.layout.blocks.should.containExactly([ ]);
                            res.ogl3.vertex.should.be('ogl3_vertex');
                            res.ogl3.fragment.should.be('ogl3_fragment');
                            res.ogl4.vertex.should.be('ogl4_vertex');
                            res.ogl4.fragment.should.be('ogl4_fragment');
                            res.hlsl.vertex.should.be('hlsl_vertex');
                            res.hlsl.fragment.should.be('hlsl_fragment');
                        case _:
                            fail('no other resource type should have been created');
                    }
                });

                final system = new ResourceSystem(events, new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel', {
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt', compiled : false },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt', compiled : false },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt', compiled : false }
                    } ]
                }));
                system.free('myParcel');
            });

            it('can remove a parcels resources from the system', {
                final files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes: [ { id : 'byte', path : '/home/user/byte.bin' } ]
                }));
                system.free('myParcel');
                
                system.get.bind('text', TextResource).should.throwType(ResourceNotFoundException);
                system.get.bind('byte', BytesResource).should.throwType(ResourceNotFoundException);
            });

            it('will reference count resources so they are only removed when no parcels reference them', {
                final files = [
                    '/home/user/text1.txt' => MockFileData.fromBytes(),
                    '/home/user/text2.txt' => MockFileData.fromBytes(),
                    '/home/user/text3.txt' => MockFileData.fromBytes()
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel1', {
                    texts: [ { id : 'text1', path : '/home/user/text1.txt' } ],
                    bytes: [ { id : 'text2', path : '/home/user/text2.txt' } ]
                }));
                system.load(Definition('myParcel2', {
                    texts: [ { id : 'text2', path : '/home/user/text2.txt' } ],
                    bytes: [ { id : 'text3', path : '/home/user/text3.txt' } ]
                }));

                system.get('text1', Resource).id.should.be('text1');
                system.get('text2', Resource).id.should.be('text2');
                system.get('text3', Resource).id.should.be('text3');

                system.free('myParcel1');
                system.get.bind('text1', Resource).should.throwType(ResourceNotFoundException);
                system.get('text2', Resource).id.should.be('text2');
                system.get('text3', Resource).id.should.be('text3');

                system.free('myParcel2');
                system.get.bind('text1', Resource).should.throwType(ResourceNotFoundException);
                system.get.bind('text2', Resource).should.throwType(ResourceNotFoundException);
                system.get.bind('text3', Resource).should.throwType(ResourceNotFoundException);
            });

            it('will decremement the references for pre-packaged parcels', {
                final files  = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(File.getBytes('bin/images.parcel'))
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(PrePackaged('images.parcel'));

                system.get('dots', ImageResource).should.beType(ImageResource);

                system.free('images.parcel');

                system.get.bind('dots', ImageResource).should.throwType(ResourceNotFoundException);
            });

            it('will decrement the resources in all pre-packaged parcels dependencies', {
                final files = [
                    'assets/parcels/images.parcel' => MockFileData.fromBytes(File.getBytes('bin/images.parcel')),
                    'assets/parcels/preload.parcel' => MockFileData.fromBytes(File.getBytes('bin/preload.parcel'))
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(PrePackaged('preload.parcel'));

                system.get('ubuntu'       , TextResource).should.beType(TextResource);
                system.get('cavesofgallet', TextResource).should.beType(TextResource);
                system.get('dots'         , ImageResource).should.beType(ImageResource);

                system.free('preload.parcel');

                system.get.bind('ubuntu'       , TextResource).should.throwType(ResourceNotFoundException);
                system.get.bind('cavesofgallet', TextResource).should.throwType(ResourceNotFoundException);
                system.get.bind('dots'         , ImageResource).should.throwType(ResourceNotFoundException);
            });

            it('will throw an exception trying to fetch a resource which does not exist', {
                final sys = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                sys.get.bind('hello', Resource).should.throwType(ResourceNotFoundException);
            });

            it('will return an empty observable when trying to load an already loaded parcel', {
                var calls = 0;

                final files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                final parcel = Definition('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes: [ { id : 'byte', path : '/home/user/byte.bin' } ]
                });

                system.load(parcel);
                system.load(parcel).subscribeFunction(() -> calls++);

                calls.should.be(1);
            });

            it('will thrown an exception when trying to get a resource as the wrong type', {
                final files  = [ '/home/user/text.txt' => MockFileData.fromText('hello world!') ];
                final system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []), CurrentThreadScheduler.current, CurrentThreadScheduler.current);
                system.load(Definition('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ]
                }));

                system.get.bind('text', BytesResource).should.throwType(InvalidResourceTypeException);
            });

            it('contains a callback for when the parcel has finished loading', {
                var result = '';
                new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current)
                    .load(Definition('myParcel', {}))
                    .subscribeFunction(() -> result = 'finished');

                result.should.be('finished');
            });

            it('contains a callback for when the parcel has failed to load', {
                var result = '';
                new ResourceSystem(new ResourceEvents(), new MockFileSystem([], []), CurrentThreadScheduler.current, CurrentThreadScheduler.current)
                    .load(Definition('myParcel', { texts : [ { id : 'text.txt', path : '' } ] }))
                    .subscribeFunction((_error : String) -> result = 'error');

                result.should.be('error');
            });
        });
    }
}
