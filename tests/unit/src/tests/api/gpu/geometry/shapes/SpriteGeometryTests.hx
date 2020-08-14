package tests.api.gpu.geometry.shapes;

import uk.aidanlee.flurry.api.gpu.camera.Camera2D;
import uk.aidanlee.flurry.api.gpu.batcher.Batcher;
import uk.aidanlee.flurry.api.gpu.geometry.shapes.SpriteGeometry;
import uk.aidanlee.flurry.api.resources.Resource.SpriteResource;
import uk.aidanlee.flurry.api.resources.Resource.SpriteFrameResource;
import buddy.BuddySuite;

using buddy.Should;

class SpriteGeometryTests extends BuddySuite
{
    public function new()
    {
        describe('SpriteGeometry', {
            final sprite = new SpriteResource('id', 'image', 0, 0, 512, 64, 0, 0, 1, 1, [
                'default' => [
                    new SpriteFrameResource(64, 64, 100, 0, 0, 0.125, 1),
                    new SpriteFrameResource(64, 64, 100, 0.125, 0, 0.25, 1)
                ],
                'walk' => [
                    new SpriteFrameResource(32, 48, 100, 0.25, 0, 0.375, 1),
                    new SpriteFrameResource(48, 64, 100, 0.375, 0, 0.5, 1),
                    new SpriteFrameResource(40, 50, 100, 0.5, 0, 0.625, 1)
                ]
            ]);

            describe('default constructor', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default'
                });

                it('will set the origin to 0x0', {
                    geom.origin.x.should.be(0);
                    geom.origin.y.should.be(0);
                });
                it('will set the scale to 1x1', {
                    geom.scale.x.should.be(1);
                    geom.scale.y.should.be(1);
                });
                it('will return the current frame width', {
                    geom.width.should.be(64);
                });
                it('will return the current frame height', {
                    geom.height.should.be(64);
                });
                it('will default the speed to 1', {
                    geom.speed.should.be(1);
                });
                it('will default the angle to 0', {
                    geom.angle.should.be(0);
                });
                it('will start playing the initial animation', {
                    geom.playing.should.be(true);
                });
                it('will add the geometry to the provided batchers', {
                    batcher.geometry.length.should.be(1);
                    batcher.geometry[0].should.be(geom);
                });
                it('will set the texture to the image of the sprite resource', {
                    switch geom.textures
                    {
                        case Some(_textures):
                            _textures.length.should.be(1);
                            _textures[0].should.be(sprite.image);
                        case None:
                            fail('expected textures but none were found');
                    }
                });
            });
            describe('custom constructor', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default',
                    xOrigin   : 32,
                    yOrigin   : 64,
                    xScale    : 1.5,
                    yScale    : 1.75,
                    speed     : 1.25,
                    angle     : 45
                });

                it('will set the origin to the provided pixel location', {
                    geom.origin.x.should.be(32);
                    geom.origin.y.should.be(64);
                });
                it('will set the scale to provided multipliers', {
                    geom.scale.x.should.be(1.5);
                    geom.scale.y.should.be(1.75);
                });
                it('will return the current scaled frame width', {
                    geom.width.should.be(64 * 1.5);
                });
                it('will return the current scaled frame height', {
                    geom.height.should.be(64 * 1.75);
                });
                it('will return the current speed multiplier', {
                    geom.speed.should.be(1.25);
                });
                it('will default the current angle in degrees', {
                    geom.angle.should.be(45);
                });
            });

            describe('manually setting frame', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default'
                });

                it('will uv the geometry to the requested frame', {
                    final index = 1;
                    final frame = sprite.animations['default'][index];

                    geom.frame(index);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will set the size to that of the requested frame', {
                    final index = 1;
                    final frame = sprite.animations['default'][index];

                    geom.frame(index);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will throw an exception when passing a frame index of less than 0', {
                    geom.frame.bind(-1).should.throwType(OutOfRangeException);
                });
                it('will throw an exception when passing a frame index greater than the max frames', {
                    geom.frame.bind(sprite.animations['default'].length).should.throwType(OutOfRangeException);
                    geom.frame.bind(sprite.animations['default'].length + 1).should.throwType(OutOfRangeException);
                });
            });

            describe('playing animation', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default'
                });

                it('will uv and resize the quad to the initial frame on creation', {
                    final frame = sprite.animations['default'][0];

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will uv and resize the quad to the initial frame when playing a new animation', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][0];

                    geom.play(anim);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will update the quad uv and size when updating past the frames duration', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][1];

                    geom.play(anim);
                    geom.update(100);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will not track update times if not playing', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][0];

                    geom.play(anim);
                    geom.playing = false;
                    geom.update(100);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will wrap around to the first frame when exceeding all in an animation', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][0];

                    geom.play(anim);
                    geom.update(100);
                    geom.update(100);
                    geom.update(100);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will throw an exception when trying to play a non-existant animation', {
                    geom.play.bind('does not exist').should.throwType(AnimationNotFoundException);
                });
            });

            describe('resetting animation', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default'
                });

                it('will uv and resize the quad to the initial frame', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][0];

                    geom.play(anim);
                    geom.update(100);
                    geom.update(100);
                    geom.restart();

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will reset time tracking for frame updates', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][0];

                    geom.play(anim);
                    geom.update(100);
                    geom.update(75);
                    geom.restart();
                    geom.update(50);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
                it('will autostart playing the animation', {
                    final anim  = 'walk';
                    final frame = sprite.animations[anim][1];

                    geom.play(anim);
                    geom.playing = false;
                    geom.restart();
                    geom.update(100);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
            });

            describe('animation speed', {
                final batcher = new Batcher({
                    camera : new Camera2D(0, 0, TopLeft, ZeroToNegativeOne),
                    shader : 0
                });
                final geom = new SpriteGeometry({
                    sprite    : sprite,
                    batchers  : [ batcher ],
                    animation : 'default'
                });

                it('acts as a multipler on the miliseconds passed into update calls', {
                    final frame = sprite.animations['default'][1];

                    geom.speed = 2;
                    geom.update(50);

                    switch geom.data
                    {
                        case Indexed(_vertices, _):
                            _vertices.floatAccess[(0 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(0 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(0 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(0 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(1 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(1 * 9) + 1].should.be(frame.height);
                            _vertices.floatAccess[(1 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(1 * 9) + 8].should.be(frame.v2);

                            _vertices.floatAccess[(2 * 9) + 0].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(2 * 9) + 7].should.be(frame.u1);
                            _vertices.floatAccess[(2 * 9) + 8].should.be(frame.v1);

                            _vertices.floatAccess[(3 * 9) + 0].should.be(frame.width);
                            _vertices.floatAccess[(3 * 9) + 1].should.be(0);
                            _vertices.floatAccess[(3 * 9) + 7].should.be(frame.u2);
                            _vertices.floatAccess[(3 * 9) + 8].should.be(frame.v1);
                        case _: fail('expected indexed vertices');
                    }
                });
            });
        });
    }
}