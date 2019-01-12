
import hxp.System;
import hxp.Log;
import hxp.Script;

class Install extends Script
{
    public function new()
    {
        super();

        Log.info('Installing Core Engine Dependencies');

        Sys.command('haxelib install haxe-concurrent 2.0.1 --quiet --never', []);
        Sys.command('haxelib git linc_opengl    https://github.com/Aidan63/linc_opengl gl-bindless-textures --quiet --never', []);
        Sys.command('haxelib git snow           https://github.com/Aidan63/snow           --quiet --never', []);
        Sys.command('haxelib git linc_directx   https://github.com/Aidan63/linc_directx   --quiet --never', []);
        Sys.command('haxelib git linc_sdl       https://github.com/Aidan63/linc_sdl       --quiet --never', []);
        Sys.command('haxelib git linc_ogg       https://github.com/snowkit/linc_ogg       --quiet --never', []);
        Sys.command('haxelib git linc_stb       https://github.com/snowkit/linc_stb       --quiet --never', []);
        Sys.command('haxelib git linc_timestamp https://github.com/snowkit/linc_timestamp --quiet --never', []);
        Sys.command('haxelib git linc_openal    https://github.com/snowkit/linc_openal    --quiet --never', []);
        Sys.command('haxelib git hxcpp          https://github.com/HaxeFoundation/hxcpp   --quiet --never', []);

        if (!flags.exists('no-test-deps'))
        {
            Log.info('Installing Test Suite Dependencies');

            Sys.command('haxelib install buddy --quiet --never', []);
            Sys.command('haxelib git mockatoo https://github.com/Aidan63/mockatoo --quiet --never', []);
        }

        if (!flags.exists('no-build-tool-deps'))
        {
            Log.info('Installing Build Tool Dependencies');
        }

        if (!flags.exists('no-parcel-tool-deps'))
        {
            Log.info('Installing Parcel Tool Dependencies');

            Sys.command('haxelib install tink_cli 0.4.1 --quiet --never', []);
        }

        if (!flags.exists('no-shader-tool-deps'))
        {
            Log.info('Installing Shader Tool Dependencies');

            // Not Yet Implemented
        }
    }
}
