package tests.api.resources;

import buddy.SingleSuite;
import uk.aidanlee.flurry.api.resources.ResourceSystem;
import uk.aidanlee.flurry.api.resources.ResourceEvents;
import uk.aidanlee.flurry.api.resources.Resource;
import uk.aidanlee.flurry.api.resources.Parcel;
import sys.io.abstractions.mock.MockFileSystem;
import sys.io.abstractions.mock.MockFileData;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class ResourceSystemTests extends SingleSuite
{
    public function new()
    {
        describe('ResourceSystem', {
            
            it('can create a parcel', {
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                var parcel = system.createParcel('myParcel', {
                    bytes: [ { id: 'bytes' } ],
                    texts: [ { id: 'texts' } ],
                    jsons: [ { id: 'jsons' } ],
                    images: [ { id: 'images' } ],
                    shaders: [ { id: 'shaders' } ],
                    parcels: [ 'parcels' ]
                });

                parcel.id.should.be('myParcel');
                parcel.list.bytes[0].id.should.be('bytes');
                parcel.list.texts[0].id.should.be('texts');
                parcel.list.jsons[0].id.should.be('jsons');
                parcel.list.images[0].id.should.be('images');
                parcel.list.shaders[0].id.should.be('shaders');
                parcel.list.parcels.should.contain('parcels');
            });

            it('can add an existing parcel to the system', {
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                var parcel = new Parcel(system, 'myParcel', {});

                system.addParcel(parcel);
            });

            it('allows manually adding resources to the system', {
                var sys = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                var res = mock(Resource);
                res.id.returns('hello');

                sys.addResource(res);
                sys.get('hello', Resource).should.be(res);
            });

            it('allows manually removing resources from the system', {
                var sys = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                var res = mock(Resource);
                res.id.returns('hello');

                sys.addResource(res);
                sys.get('hello', Resource).should.be(res);
                sys.removeResource(res);
                sys.get.bind('hello', Resource).should.throwType(ResourceNotFoundException);
            });

            it('can load a parcels resources into the system', {
                var files = [
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
                var system = new ResourceSystem(new ResourceEvents(), new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    texts   : [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes   : [ { id : 'byte', path : '/home/user/byte.bin' } ],
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    jsons   : [ { id : 'json', path : '/home/user/json.json' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt' },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt' },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt' }
                    } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();

                var res = system.get('text', TextResource);
                res.id.should.be('text');
                res.content.should.be('hello world!');

                var res = system.get('byte', BytesResource);
                res.id.should.be('byte');
                res.bytes.toString().should.be('hello world!');

                var res = system.get('dots', ImageResource);
                res.id.should.be('dots');
                res.width.should.be(2);
                res.height.should.be(2);

                var res = system.get('json', JSONResource);
                res.id.should.be('json');

                var res = system.get('shdr', ShaderResource);
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

            it('fires events for when images and shaders are added', {
                var files = [
                    '/home/user/dots.png'  => MockFileData.fromBytes(haxe.Resource.getBytes('dots-data')),
                    '/home/user/shdr.json' => MockFileData.fromText(' { "textures" : [ "defaultTexture" ], "blocks" : [] } '),
                    '/home/user/ogl3_vertex.txt'   => MockFileData.fromText('ogl3_vertex'),
                    '/home/user/ogl3_fragment.txt' => MockFileData.fromText('ogl3_fragment'),
                    '/home/user/ogl4_vertex.txt'   => MockFileData.fromText('ogl4_vertex'),
                    '/home/user/ogl4_fragment.txt' => MockFileData.fromText('ogl4_fragment'),
                    '/home/user/hlsl_vertex.txt'   => MockFileData.fromText('hlsl_vertex'),
                    '/home/user/hlsl_fragment.txt' => MockFileData.fromText('hlsl_fragment')
                ];
                var events = new ResourceEvents();
                events.created.add(_created -> {
                    if (Std.is(_created.type, ShaderResource))
                    {
                        _created.resource.should.beType(ShaderResource);
                        var res : ShaderResource = cast _created.resource;

                        res.id.should.be('shdr');
                        res.layout.textures.should.containExactly([ 'defaultTexture' ]);
                        res.layout.blocks.should.containExactly([ ]);
                        res.ogl3.vertex.should.be('ogl3_vertex');
                        res.ogl3.fragment.should.be('ogl3_fragment');
                        res.ogl4.vertex.should.be('ogl4_vertex');
                        res.ogl4.fragment.should.be('ogl4_fragment');
                        res.hlsl.vertex.should.be('hlsl_vertex');
                        res.hlsl.fragment.should.be('hlsl_fragment');
                    }
                    if (Std.is(_created.type, ImageResource))
                    {
                        _created.resource.should.be(ImageResource);
                        var res : ImageResource = cast _created.resource;

                        res.id.should.be('dots');
                        res.width.should.be(2);
                        res.height.should.be(2);
                    }
                });

                var system = new ResourceSystem(events, new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt' },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt' },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt' }
                    } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
            });

            it('fires events for when images and shaders are removed', {
                var files = [
                    '/home/user/dots.png'  => MockFileData.fromBytes(haxe.Resource.getBytes('dots-data')),
                    '/home/user/shdr.json' => MockFileData.fromText(' { "textures" : [ "defaultTexture" ], "blocks" : [] } '),
                    '/home/user/ogl3_vertex.txt'   => MockFileData.fromText('ogl3_vertex'),
                    '/home/user/ogl3_fragment.txt' => MockFileData.fromText('ogl3_fragment'),
                    '/home/user/ogl4_vertex.txt'   => MockFileData.fromText('ogl4_vertex'),
                    '/home/user/ogl4_fragment.txt' => MockFileData.fromText('ogl4_fragment'),
                    '/home/user/hlsl_vertex.txt'   => MockFileData.fromText('hlsl_vertex'),
                    '/home/user/hlsl_fragment.txt' => MockFileData.fromText('hlsl_fragment')
                ];
                var events = new ResourceEvents();
                events.removed.add(_removed -> {
                    if (Std.is(_removed.type, ShaderResource))
                    {
                        _removed.resource.should.beType(ShaderResource);
                        var res : ShaderResource = cast _removed.resource;

                        res.id.should.be('shdr');
                        res.layout.textures.should.containExactly([ 'defaultTexture' ]);
                        res.layout.blocks.should.containExactly([ ]);
                        res.ogl3.vertex.should.be('ogl3_vertex');
                        res.ogl3.fragment.should.be('ogl3_fragment');
                        res.ogl4.vertex.should.be('ogl4_vertex');
                        res.ogl4.fragment.should.be('ogl4_fragment');
                        res.hlsl.vertex.should.be('hlsl_vertex');
                        res.hlsl.fragment.should.be('hlsl_fragment');
                    }
                    if (Std.is(_removed.type, ImageResource))
                    {
                        _removed.resource.should.be(ImageResource);
                        var res : ImageResource = cast _removed.resource;

                        res.id.should.be('dots');
                        res.width.should.be(2);
                        res.height.should.be(2);
                    }
                });

                var system = new ResourceSystem(events, new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    images  : [ { id : 'dots', path : '/home/user/dots.png' } ],
                    shaders : [ { id : 'shdr', path : '/home/user/shdr.json',
                        ogl3 : { vertex : '/home/user/ogl3_vertex.txt', fragment : '/home/user/ogl3_fragment.txt' },
                        ogl4 : { vertex : '/home/user/ogl4_vertex.txt', fragment : '/home/user/ogl4_fragment.txt' },
                        hlsl : { vertex : '/home/user/hlsl_vertex.txt', fragment : '/home/user/hlsl_fragment.txt' }
                    } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                system.free('myParcel');
            });

            it('can remove a parcels resources from the system', {
                var files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes: [ { id : 'byte', path : '/home/user/byte.bin' } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                system.free('myParcel');
                system.get.bind('text', TextResource).should.throwType(ResourceNotFoundException);
                system.get.bind('byte', BytesResource).should.throwType(ResourceNotFoundException);
            });

            it('will reference count resources so they are only removed when no parcels reference them', {
                var files = [
                    '/home/user/text1.txt' => MockFileData.fromBytes(),
                    '/home/user/text2.txt' => MockFileData.fromBytes(),
                    '/home/user/text3.txt' => MockFileData.fromBytes()
                ];
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem(files, []));
                system.createParcel('parcel1', {
                    texts: [ { id : 'text1', path : '/home/user/text1.txt' } ],
                    bytes: [ { id : 'text2', path : '/home/user/text2.txt' } ]
                }).load();
                system.createParcel('parcel2', {
                    texts: [ { id : 'text2', path : '/home/user/text2.txt' } ],
                    bytes: [ { id : 'text3', path : '/home/user/text3.txt' } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                system.get('text1', Resource).id.should.be('text1');
                system.get('text2', Resource).id.should.be('text2');
                system.get('text3', Resource).id.should.be('text3');

                system.free('parcel2');
                system.get.bind('text3', Resource).should.throwType(ResourceNotFoundException);
                system.get('text1', Resource).id.should.be('text1');
                system.get('text2', Resource).id.should.be('text2');

                system.free('parcel1');
                system.get.bind('text3', Resource).should.throwType(ResourceNotFoundException);
                system.get.bind('text2', Resource).should.throwType(ResourceNotFoundException);
                system.get.bind('text1', Resource).should.throwType(ResourceNotFoundException);
            });

            it('will throw an exception trying to fetch a resource which does not exist', {
                var sys = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                sys.get.bind('hello', Resource).should.throwType(ResourceNotFoundException);
            });

            it('will throw an exception when trying to load an already loaded parcel', {
                var files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes: [ { id : 'byte', path : '/home/user/byte.bin' } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                system.load.bind('myParcel').should.throwType(ParcelAlreadyLoadedException);
            });

            it('will throw an exception when trying to load a parcel which has not been added to the system', {
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                system.load.bind('myParcel').should.throwType(ParcelNotAddedException);
            });

            it('will thrown an exception when trying to get a resource as the wrong type', {
                var files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];
                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem(files, []));
                system.createParcel('myParcel', {
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ]
                }).load();

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                system.get.bind('text', BytesResource).should.throwType(InvalidResourceType);
            });

            it('contains a callback for when the parcel has finished loading', {
                var result = '';

                var parcel = mock(Parcel);
                parcel.id.returns('myParcel');
                parcel.list.returns({});
                parcel.onLoaded.returns(_ -> result = 'finished');

                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                system.addParcel(parcel);
                system.load('myParcel');

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                result.should.be('finished');
            });

            it('contains a callback for when the parcel has loaded an individual resource', {
                var files = [
                    '/home/user/text.txt' => MockFileData.fromText('hello world!'),
                    '/home/user/byte.bin' => MockFileData.fromText('hello world!')
                ];

                var results = [];
                var parcel  = mock(Parcel);
                parcel.id.returns('myParcel');
                parcel.list.returns({
                    texts: [ { id : 'text', path : '/home/user/text.txt' } ],
                    bytes: [ { id : 'byte', path : '/home/user/byte.bin' } ]
                });
                parcel.onProgress.returns(_ -> results.push(_));

                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem(files, []));
                system.addParcel(parcel);
                system.load('myParcel');

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                results.should.containExactly([ 0.5, 1.0 ]);
            });

            it('contains a callback for when the parcel has failed to load', {
                var result = '';

                var parcel = mock(Parcel);
                parcel.id.returns('myParcel');
                parcel.list.returns({ texts : [ { id : 'text.txt' } ] });
                parcel.onFailed.returns(_ -> result = _);

                var system = new ResourceSystem(mock(ResourceEvents), new MockFileSystem([], []));
                system.addParcel(parcel);
                system.load('myParcel');

                // Wait an amount of time then pump events.
                // Hopefully this will be enough time for the parcel to load.
                Sys.sleep(0.1);

                system.update();
                result.should.not.be('');
            });
        });
    }
}
