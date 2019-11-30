#!/bin/bash

# Install linux specific dependencies
if [ $AGENT_OS == 'Linux' ]; then
    sudo apt-get install -y gcc-multilib g++-multilib libgl1-mesa-dev libglu1-mesa-dev libopenal-dev libxrandr-dev libxinerama-dev libasound2-dev libsdl2-dev imagemagick xvfb libgl1-mesa-dri libgl1-mesa-glx
fi

# Install lix and download flurry dependencies
npm install

npx lix download

# Build the hxcpp tools
cd $(npx haxelib path hxcpp | tail -1 | tr -d '\n')
npm install lix
cd tools/hxcpp
npx haxe compile.hxml
