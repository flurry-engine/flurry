package tests;

import parcel.Types.JsonAtlas;
import parcel.Types.JsonAtlasPage;
import parcel.Types.JsonSprite;
import parcel.Types.JsonFontDefinition;
import haxe.io.BytesOutput;
import haxe.io.Path;
import haxe.io.Bytes in HaxeBytes;
import haxe.io.BytesInput;
import Types.Project;
import parcel.Packer;
import parcel.Types.JsonDefinition;
import sys.io.abstractions.mock.MockFileData;
import sys.io.abstractions.mock.MockFileSystem;
import uk.aidanlee.flurry.api.resources.Resource.ImageFrameResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.ImageResource;
import uk.aidanlee.flurry.api.resources.Resource.FontResource;
import uk.aidanlee.flurry.api.resources.Resource.ResourceType;
import uk.aidanlee.flurry.api.resources.Resource.Resource;
import uk.aidanlee.flurry.api.stream.ParcelInput;
import uk.aidanlee.flurry.api.maths.Hash;
import uk.aidanlee.flurry.api.core.Result;
import uk.aidanlee.flurry.api.core.Unit;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using mockatoo.Mockatoo;
using buddy.Should;
using Lambda;

class PackerTests extends BuddySuite
{
    public function new()
    {
        describe('Parcel Generation', {
            describe('shaders', {
                describe('generating opengl 3.3 shaders', {
                    //
                });
                describe('generating dxbc shaders', {
                    //
                });
            });
            it('will call msdf-atlas-gen to generate font sheets', {
                final assets : JsonDefinition = {
                    assets : {
                        bytes : [],
                        texts : [],
                        fonts : [
                            { id : 'custom_font', path : 'font.ttf' }
                        ],
                        images : [],
                        sheets : [],
                        sprites : [],
                        shaders : []
                    },
                    parcels : [ 
                        { name : 'parcel', fonts : [ 'custom_font' ] }
                    ]
                }
                final fs = new MockFileSystem([
                    'assets.json' => MockFileData.fromText(tink.Json.stringify(assets))
                ], []);
                final project = project();
                final proc    = mock(Proc);
                final packer  = new Packer(project, Mock, fs, proc);

                // Intercept calls to msdf-atlas-gen and place a pre-defined json and dummy image in the fs.
                Mockatoo.when(proc.run(Path.join([ Utils.toolPath(project), Utils.msdfAtlasExecutable() ]), anyIterator)).thenCall(f -> {
                    final args = (cast f[1] : Array<String>);
                    final img  = args[7];
                    final json = args[9];

                    fs.files[img]  = MockFileData.fromBytes(createDummyPng());
                    fs.files[json] = MockFileData.fromText(createDummyJson());

                    return Success(Unit.value);
                });
                Mockatoo.when(proc.run(Path.join([ Utils.toolPath(project), Utils.atlasCreatorExecutable() ]), anyIterator)).thenCall(f -> {
                    final args   = (cast f[1] : Array<String>);
                    final outDir = args[3];
                    final parcel = args[5];
                    final atlas  = createAtlas([
                        { image: '$parcel.png', width: 8, height: 8, packed: [
                            { file: 'custom_font', x:  0, y: 0, width: 8, height: 8 }
                        ] }
                    ]);

                    fs.files.set(Path.join([ outDir, '$parcel.png' ]), MockFileData.fromBytes(createDummyPng()));
                    fs.files.set(Path.join([ outDir, '$parcel.json' ]), MockFileData.fromText(atlas));

                    return Success(Unit.value);
                });

                switch packer.create('assets.json')
                {
                    case Success(data):
                        // Unpack the serialised bytes.
                        switch unpack(fs.file.getBytes(data[0].file))
                        {
                            case Success(resources):
                                // Check the image that should have been made from packing the font
                                final image = (cast resources.find(r -> r.name == 'parcel.png') : ImageResource);
                                image.id.should.be(Hash.hash(image.name));
                                image.type.should.equal(ResourceType.Image);
                                image.width.should.be(8);
                                image.height.should.be(8);

                                // Check our font
                                final resource = (cast resources.find(r -> r.name == 'custom_font') : FontResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.Font);
                                resource.image.should.be(image.id);
                                resource.x.should.be(0);
                                resource.y.should.be(0);
                                resource.width.should.be(8);
                                resource.height.should.be(8);
                                resource.u1.should.be(0);
                                resource.v1.should.be(0);
                                resource.u2.should.be(1);
                                resource.v2.should.be(1);
                            case Failure(message):
                                fail(message);
                        }
                    case Failure(message):
                        fail(message);
                }
            });
            it('will call atlas-creator tool to combine all images', {
                final assets : JsonDefinition = {
                    assets : {
                        bytes : [],
                        texts : [],
                        fonts : [],
                        images : [
                            { id : 'img1', path : 'img1.png' },
                            { id : 'img2', path : 'img2.png' },
                            { id : 'img3', path : 'img3.png' }
                        ],
                        sheets : [],
                        sprites : [],
                        shaders : []
                    },
                    parcels : [ 
                        { name : 'parcel', images : [ 'img1', 'img2', 'img3' ] }
                    ]
                }
                final fs = new MockFileSystem([
                    'assets.json' => MockFileData.fromText(tink.Json.stringify(assets)),
                    'img1.png' => MockFileData.fromBytes(createDummyPng( 4, 6)),
                    'img2.png' => MockFileData.fromBytes(createDummyPng( 8, 3)),
                    'img3.png' => MockFileData.fromBytes(createDummyPng(10, 2))
                ], []);
                final project = project();
                final proc    = mock(Proc);
                final packer  = new Packer(project, Mock, fs, proc);

                Mockatoo.when(proc.run(Path.join([ Utils.toolPath(project), Utils.atlasCreatorExecutable() ]), anyIterator)).thenCall(f -> {
                    final args   = (cast f[1] : Array<String>);
                    final outDir = args[3];
                    final parcel = args[5];
                    final atlas  = createAtlas([
                        { image: '$parcel.png', width: 22, height: 6, packed: [
                            { file: 'img1', x:  0, y: 0, width:  4, height: 6 },
                            { file: 'img2', x:  4, y: 0, width:  8, height: 3 },
                            { file: 'img3', x: 12, y: 0, width: 10, height: 2 }
                        ] }
                    ]);

                    fs.files.set(Path.join([ outDir, '$parcel.png' ]), MockFileData.fromBytes(createDummyPng(22, 6)));
                    fs.files.set(Path.join([ outDir, '$parcel.json' ]), MockFileData.fromText(atlas));

                    return Success(Unit.value);
                });

                switch packer.create('assets.json')
                {
                    case Success(data):
                        switch unpack(fs.file.getBytes(data[0].file))
                        {
                            case Success(resources):
                                final image = (cast resources.find(r -> r.name == 'parcel.png') : ImageResource);
                                image.id.should.be(Hash.hash(image.name));
                                image.type.should.equal(ResourceType.Image);
                                image.width.should.be(22);
                                image.height.should.be(6);
        
                                final resource = (cast resources.find(r -> r.name == 'img1') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(0);
                                resource.y.should.be(0);
                                resource.width.should.be(4);
                                resource.height.should.be(6);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                final resource = (cast resources.find(r -> r.name == 'img2') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(4);
                                resource.y.should.be(0);
                                resource.width.should.be(8);
                                resource.height.should.be(3);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                final resource = (cast resources.find(r -> r.name == 'img3') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(12);
                                resource.y.should.be(0);
                                resource.width.should.be(10);
                                resource.height.should.be(2);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
                            case Failure(message):
                                fail(message);
                        }
                    case Failure(message):
                        fail(message);
                }
            });
            it('will call aseprite to generate sprite sheets for packing', {
                final assets : JsonDefinition = {
                    assets : {
                        bytes : [],
                        texts : [],
                        fonts : [],
                        images : [],
                        sheets : [],
                        sprites : [
                            { id : 'sprite', path : 'sprites/sprite.aseprite' }
                        ],
                        shaders : []
                    },
                    parcels : [ 
                        { name : 'parcel', sprites : [ 'sprite' ] }
                    ]
                }
                final fs = new MockFileSystem([
                    'assets.json' => MockFileData.fromText(tink.Json.stringify(assets)),
                    'sprites/sprite.aseprite' => MockFileData.fromText('')
                ], []);
                final project = project();
                final proc    = mock(Proc);
                final packer  = new Packer(project, Mock, fs, proc);

                Mockatoo.when(proc.run('C:/Program Files/Aseprite/aseprite.exe', anyIterator)).thenCall(f -> {
                    final args = (cast f[1] : Array<String>);
                    final png  = args[3];
                    final json = args[5];
                    final spr : JsonSprite = {
                        meta: {
                            app: '', scale: '', size: { w: 64, h: 32 }, format: '', image: '', version: '', frameTags: [
                                { name: 'anim_1', direction: '', from: 0, to: 1 },
                                { name: 'anim_2', direction: '', from: 2, to: 5 }
                            ]
                        },
                        frames: [
                            {
                                filename: '0',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 0, y: 0, w: 32, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            },
                            {
                                filename: '1',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 32, y: 0, w: 32, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            },
                            {
                                filename: '2',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 0, y: 16, w: 16, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            },
                            {
                                filename: '3',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 16, y: 16, w: 16, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            },
                            {
                                filename: '4',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 32, y: 16, w: 16, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            },
                            {
                                filename: '5',
                                duration: 100,
                                trimmed: false,
                                rotated: false,
                                frame: { x: 48, y: 16, w: 16, h: 16 },
                                sourceSize: { w: 0, h: 0 },
                                spriteSourceSize: { x: 0, y: 0, w: 0, h: 0 }
                            }
                        ]
                    }

                    fs.files.set(png, MockFileData.fromText(''));
                    fs.files.set(json, MockFileData.fromText(tink.Json.stringify(spr)));

                    return Success(Unit.value);
                });

                Mockatoo.when(proc.run(Path.join([ Utils.toolPath(project), Utils.atlasCreatorExecutable() ]), anyIterator)).thenCall(f -> {
                    final args   = (cast f[1] : Array<String>);
                    final outDir = args[3];
                    final parcel = args[5];
                    final atlas  = createAtlas([
                        { image: '$parcel.png', width: 64, height: 32, packed: [
                            { file: 'sprite', x: 0, y: 0, width: 64, height: 32 },
                        ] }
                    ]);

                    fs.files.set(Path.join([ outDir, '$parcel.png' ]), MockFileData.fromBytes(createDummyPng(64, 32)));
                    fs.files.set(Path.join([ outDir, '$parcel.json' ]), MockFileData.fromText(atlas));

                    return Success(Unit.value);
                });

                switch packer.create('assets.json')
                {
                    case Success(data):
                        switch unpack(fs.file.getBytes(data[0].file))
                        {
                            case Success(resources):
                                final image = (cast resources.find(r -> r.name == 'parcel.png') : ImageResource);
                                image.id.should.be(Hash.hash(image.name));
                                image.type.should.equal(ResourceType.Image);
                                image.width.should.be(64);
                                image.height.should.be(32);
        
                                final resource = (cast resources.find(r -> r.name == 'sprite') : SpriteResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.Sprite);
                                resource.image.should.be(image.id);
                                resource.x.should.be(0);
                                resource.y.should.be(0);
                                resource.width.should.be(64);
                                resource.height.should.be(32);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                resource.animations.exists('anim_1').should.be(true);
                                resource.animations.exists('anim_2').should.be(true);
        
                                resource.animations['anim_1'].length.should.be(2);
                                final frame = resource.animations['anim_1'][0];
                                frame.duration.should.be(100);
                                frame.width.should.be(32);
                                frame.height.should.be(16);
                                frame.u1.should.be(0);
                                frame.v1.should.be(0);
                                frame.u2.should.be(0.5);
                                frame.v2.should.be(0.5);
                                final frame = resource.animations['anim_1'][1];
                                frame.duration.should.be(100);
                                frame.width.should.be(32);
                                frame.height.should.be(16);
                                frame.u1.should.be(0.5);
                                frame.v1.should.be(0);
                                frame.u2.should.be(1);
                                frame.v2.should.be(0.5);
        
                                resource.animations['anim_2'].length.should.be(4);
                                final frame = resource.animations['anim_2'][0];
                                frame.duration.should.be(100);
                                frame.width.should.be(16);
                                frame.height.should.be(16);
                                frame.u1.should.be(0);
                                frame.v1.should.be(0.5);
                                frame.u2.should.be(0.25);
                                frame.v2.should.be(1);
                                final frame = resource.animations['anim_2'][1];
                                frame.duration.should.be(100);
                                frame.width.should.be(16);
                                frame.height.should.be(16);
                                frame.u1.should.be(0.25);
                                frame.v1.should.be(0.5);
                                frame.u2.should.be(0.5);
                                frame.v2.should.be(1);
                                final frame = resource.animations['anim_2'][2];
                                frame.duration.should.be(100);
                                frame.width.should.be(16);
                                frame.height.should.be(16);
                                frame.u1.should.be(0.5);
                                frame.v1.should.be(0.5);
                                frame.u2.should.be(0.75);
                                frame.v2.should.be(1);
                                final frame = resource.animations['anim_2'][3];
                                frame.duration.should.be(100);
                                frame.width.should.be(16);
                                frame.height.should.be(16);
                                frame.u1.should.be(0.75);
                                frame.v1.should.be(0.5);
                                frame.u2.should.be(1);
                                frame.v2.should.be(1);
                            case Failure(message):
                                fail(message);
                        }
                    case Failure(message):
                        fail(message);
                }
            });
            it('will create images frames for pre-computed atlases', {
                final assets : JsonDefinition = {
                    assets : {
                        bytes : [],
                        texts : [],
                        fonts : [],
                        images : [],
                        sheets : [
                            { id : 'atlas', path : 'atlas/sheet.atlas' }
                        ],
                        sprites : [],
                        shaders : []
                    },
                    parcels : [ 
                        { name : 'parcel', sheets : [ 'atlas' ] }
                    ]
                }
                final fs = new MockFileSystem([
                    'assets.json' => MockFileData.fromText(tink.Json.stringify(assets)),
                    'atlas/sheet.atlas' => MockFileData.fromText(haxe.Resource.getString('multi_page_atlas')),
                    'atlas/image.png'   => MockFileData.fromBytes(createDummyPng(512, 256)),
                    'atlas/image2.png'  => MockFileData.fromBytes(createDummyPng(512, 256)),
                ], []);
                final project = project();
                final proc    = mock(Proc);
                final packer  = new Packer(project, Mock, fs, proc);

                Mockatoo.when(proc.run(Path.join([ Utils.toolPath(project), Utils.atlasCreatorExecutable() ]), anyIterator)).thenCall(f -> {
                    final args   = (cast f[1] : Array<String>);
                    final outDir = args[3];
                    final parcel = args[5];
                    final atlas  = createAtlas([
                        { image: '$parcel.png', width: 1024, height: 256, packed: [
                            { file: 'image', x:   0, y: 0, width: 512, height: 256 },
                            { file: 'image2', x: 512, y: 0, width: 512, height: 256 }
                        ] }
                    ]);

                    fs.files.set(Path.join([ outDir, '$parcel.png' ]), MockFileData.fromBytes(createDummyPng(1024, 256)));
                    fs.files.set(Path.join([ outDir, '$parcel.json' ]), MockFileData.fromText(atlas));

                    return Success(Unit.value);
                });

                switch packer.create('assets.json')
                {
                    case Success(data):
                        switch unpack(fs.file.getBytes(data[0].file))
                        {
                            case Success(resources):
                                final image = (cast resources.find(r -> r.name == 'parcel.png') : ImageResource);
                                image.type.should.equal(ResourceType.Image);
                                image.id.should.be(Hash.hash(image.name));
                                image.width.should.be(1024);
                                image.height.should.be(256);
        
                                final resource = (cast resources.find(r -> r.name == 'section_1') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(4);
                                resource.y.should.be(128);
                                resource.width.should.be(64);
                                resource.height.should.be(96);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                final resource = (cast resources.find(r -> r.name == 'section_2') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(16);
                                resource.y.should.be(0);
                                resource.width.should.be(48);
                                resource.height.should.be(32);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                final resource = (cast resources.find(r -> r.name == 'section_3') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(560);
                                resource.y.should.be(95);
                                resource.width.should.be(184);
                                resource.height.should.be(35);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
        
                                final resource = (cast resources.find(r -> r.name == 'section_4') : ImageFrameResource);
                                resource.id.should.be(Hash.hash(resource.name));
                                resource.type.should.equal(ResourceType.ImageFrame);
                                resource.image.should.be(image.id);
                                resource.x.should.be(554);
                                resource.y.should.be(16);
                                resource.width.should.be(45);
                                resource.height.should.be(192);
                                resource.u1.should.beCloseTo(resource.x / image.width);
                                resource.v1.should.beCloseTo(resource.y / image.height);
                                resource.u2.should.beCloseTo((resource.x + resource.width) / image.width);
                                resource.v2.should.beCloseTo((resource.y + resource.height) / image.height);
                            case Failure(message):
                                fail(message);
                        }
                    case Failure(message):
                        fail(message);
                }
            });
        });
    }

    function unpack(_bytes : HaxeBytes) : Result<Array<Resource>, String>
    {
        final input  = new BytesInput(_bytes);
        final stream = new ParcelInput(input);
        final read   = [];

        switch stream.readHeader()
        {
            case Success(header):
                for (_ in 0...header.assets)
                {
                    switch stream.readAsset()
                    {
                        case Success(asset): read.push(asset);
                        case Failure(reason):
                            stream.close();
                            return Failure(reason);
                    }
                }
            case Failure(reason):
                stream.close();
                return Failure(reason);
        }

        stream.close();

        return Success(read);
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
            },
            parcels : [ 'assets.json' ]
        }

    function createDummyJson() : String
    {
        final data : JsonFontDefinition = {
            atlas   : { width: 8, height: 8, yOrigin: '', size: 0, distanceRange: 0, type: '' },
            metrics : { lineHeight : 0, ascender : 0, descender : 0, underlineY: 0, underlineThickness : 0 },
            kerning : [],
            glyphs  : [
                {
                    unicode: 'a'.code,
                    advance: 0.12,
                    atlasBounds: { left: 0, top: 4, right: 4, bottom: 0 },
                    planeBounds: { left: 0, top: 0.5, right: 0.5, bottom: 0 }
                },
                {
                    unicode: 'A'.code,
                    advance: 0.12,
                    atlasBounds: { left: 4, top: 4, right: 0, bottom: 0 },
                    planeBounds: { left: 0.5, top: 0.5, right: 0, bottom: 0 }
                },
                {
                    unicode: 'b'.code,
                    advance: 0.12,
                    atlasBounds: { left: 0, top: 0, right: 4, bottom: 4 },
                    planeBounds: { left: 0, top: 0, right: 0.5, bottom: 0.5 }
                },
                {
                    unicode: 'B'.code,
                    advance: 0.12,
                    atlasBounds: { left: 4, top: 0, right: 0, bottom: 4 },
                    planeBounds: { left: 0.5, top: 0, right: 0, bottom: 0.5 }
                }
            ]
        }

        return tink.Json.stringify(data);
    }

    function createDummyPng(_width = 8, _height = 8) : HaxeBytes
    {
        final output = new BytesOutput();
        final writer = new format.png.Writer(output);
        final data   = format.png.Tools.build32BGRA(_width, _height, HaxeBytes.alloc(_width * _height * 4));
        
        writer.write(data);

        return output.getBytes();
    }

    function createAtlas(_pages : Array<JsonAtlasPage>) : String
    {
        final data : JsonAtlas = {
            name  : 'parcel',
            pages : _pages
        }

        return tink.Json.stringify(data);
    }
}