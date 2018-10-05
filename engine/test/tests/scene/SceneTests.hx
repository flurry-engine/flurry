package tests.scene;

import uk.aidanlee.scene.Scene;
import buddy.BuddySuite;
import mockatoo.Mockatoo.*;

using buddy.Should;
using mockatoo.Mockatoo;

class SceneTests extends BuddySuite
{
    var root : Scene;

    public function new()
    {
        describe('Scene', {
            beforeEach({
                root = new Scene('root', null, null, null, null, null);
                root.addChild(Scene, 'root/child2');
                root.addChild(Scene, 'root/child3');
                root.addChild(Scene, 'root/child4');
                var child1 = root.addChild(Scene, 'root/child1');

                child1.addChild(Scene, 'root/child1/child1');
                child1.addChild(Scene, 'root/child1/child2').addChild(Scene, 'root/child1/child2/child1');
            });

            it('Can recursively search the scene tree for a child with a specific name', {
                var found : Scene = root.getChild('root/child1/child2/child1');

                found.should.not.be(null);
                found.name.should.be('root/child1/child2/child1');

                var found : Scene = root.getChild('does not exist');
                found.should.be(null);
            });

            it('Can add extra default scenes into the tree', {
                var found : Scene = root.getChild('root/child1/child2/child1');
                found.addChild(Scene, 'root/child1/child2/child1/child1');

                var found : Scene = root.getChild('root/child1/child2/child1/child1');
                found.should.not.be(null);
                found.name.should.be('root/child1/child2/child1/child1');
            });

            it('Can add extra user defined scenes into the tree with custom constructor arguments', {
                var found : Scene = root.getChild('root/child1/child2/child1');
                found.addChild(OtherScene, 'root/child1/child2/child1/child1', [ 7, 'hello' ]);

                var found = root.getChild('root/child1/child2/child1/child1', false, OtherScene);
                found.should.not.be(null);
                found.name.should.be('root/child1/child2/child1/child1');
                found.number.should.be(7);
                found.string.should.be('hello');
            });

            it('Can remove a child and its children from a scene tree', {
                var found : Scene = root.getChild('root/child1');
                found.removeChild(root.getChild('root/child1/child2'));

                var found : Scene = root.getChild('root/child1/child2');
                found.should.be(null);
                var found : Scene = root.getChild('root/child1/child2/child1');
                found.should.be(null);
            });
        });
    }
}

private class OtherScene extends Scene
{
    public final number : Int;

    public final string : String;

    public function new(_name : String, _snow : snow.Snow, _parent : Scene, _renderer : uk.aidanlee.gpu.Renderer, _resources : uk.aidanlee.resources.ResourceSystem, _events : snow.api.Emitter<Int>, _number : Int, _string : String)
    {
        super(_name, _snow, _parent, _renderer, _resources, _events);

        number = _number;
        string = _string;
    }
}
