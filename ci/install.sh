#!/bin/bash

# Install linux specific dependencies
if [ $AGENT_OS == 'Linux' ]; then
    sudo apt-get install -y gcc-multilib g++-multilib libgl1-mesa-dev libglu1-mesa-dev mesa-utils libopenal-dev libxrandr-dev libxinerama-dev libasound2-dev libsdl2-dev
fi

# Install lix and download flurry dependencies
npm ci

# Build the hxcpp tools
# cd $(npx haxelib path hxcpp | tail -1 | tr -d '\n')
# npm install lix
# cd tools/hxcpp
# npx haxe compile.hxml