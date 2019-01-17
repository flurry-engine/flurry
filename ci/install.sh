#!/bin/bash

export PATH=$PATH:$BASE_DIR/haxe
export PATH=$PATH:$BASE_DIR/neko
export HAXE_STD_PATH=$BASE_DIR/haxe/std
export LD_LIBRARY_PATH=$BASE_DIR/neko

mkdir $BASE_DIR/haxe
mkdir $BASE_DIR/neko

# Install haxe for each platform
case "$AGENT_OS" in
    "Linux")
        export PATH=$PATH:$BASE_DIR/haxe
        export PATH=$PATH:$BASE_DIR/neko

        curl http://hxbuilds.s3-website-us-east-1.amazonaws.com/builds/haxe/linux64/haxe_latest.tar.gz -o haxe.tar.gz -# -L
        tar -xzf haxe.tar.gz -C $BASE_DIR/haxe --strip-components=1

        curl https://github.com/HaxeFoundation/neko/releases/download/v2-2-0/neko-2.2.0-linux64.tar.gz -o neko.tar.gz -# -L
        tar -xzf neko.tar.gz -C $BASE_DIR/neko --strip-components=1

        sudo apt-get install -y gcc-multilib g++-multilib libgl1-mesa-dev libglu1-mesa-dev libopenal-dev libxrandr-dev libxinerama-dev libasound2-dev libsdl2-dev
        ;;
    "Darwin")
        mkdir -p /usr/local/lib/haxe
        mkdir -p /usr/local/bin

        curl http://hxbuilds.s3-website-us-east-1.amazonaws.com/builds/haxe/mac/haxe_latest.tar.gz -o haxe.tar.gz -# -L
        tar -xzf haxe.tar.gz -C $BASE_DIR/haxe --strip-components=1

        cp -Rf $BASE_DIR/haxe/* /usr/local/lib/haxe
        ln -s /usr/local/lib/haxe/haxe /usr/local/bin/haxe
        cp /usr/local/lib/haxe/haxelib /usr/local/bin/haxelib
        mkdir -p /usr/local/lib/haxe/lib
        chmod 777 /usr/local/lib/haxe/lib

        curl https://github.com/HaxeFoundation/neko/releases/download/v2-2-0/neko-2.2.0-osx64.tar.gz -o neko.tar.gz -# -L
        tar -xzf neko.tar.gz -C $BASE_DIR/neko --strip-components=1

        mkdir -p /usr/local/lib/neko
        cp -Rf $BASE_DIR/neko/* /usr/local/lib/neko
        ln -s /usr/local/lib/neko/neko /usr/local/bin/neko
        ln -s /usr/local/lib/neko/nekoc /usr/local/bin/nekoc
        ln -s /usr/local/lib/neko/nekoml /usr/local/bin/nekoml
        ln -s /usr/local/lib/neko/nekotools /usr/local/bin/nekotools
        ln -s /usr/local/lib/neko/libneko.dylib /usr/local/lib/libneko.dylib
        ln -s /usr/local/lib/neko/libneko.2.dylib /usr/local/lib/libneko.2.dylib
        ln -s /usr/local/lib/neko/libneko.2.2.0.dylib /usr/local/lib/libneko.2.2.0.dylib
        ;;
esac

mkdir $BASE_DIR/haxelib
haxelib setup $BASE_DIR/haxelib

haxelib dev flurry $SOURCE_DIR
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp
haxelib git hxp https://github.com/openfl/hxp.git
haxelib git hxtelemetry https://github.com/jcward/hxtelemetry.git
haxelib git linc_imgui https://github.com/Aidan63/linc_imgui.git

haxelib run flurry install

cd $BASE_DIR/haxelib/hxcpp/git/tools/run
haxe compile.hxml
cd $BASE_DIR/haxelib/hxcpp/git/tools/hxcpp
haxe compile.hxml