#!/bin/bash

# Install linux specific dependencies
if [ $AGENT_OS == 'Linux' ]; then
    sudo apt-get install -y gcc-multilib g++-multilib libgl1-mesa-dev libglu1-mesa-dev libopenal-dev libxrandr-dev libxinerama-dev libasound2-dev libsdl2-dev
fi

# Install lix and download flurry dependencies
npm install git+https://git@github.com/starburst997/lix.client.git --global

lix download

# Build the hxcpp tools
cd $(haxelib path hxcpp | tail -1 | tr -d '\n')/tools/run
haxe compile.hxml
cd $(haxelib path hxcpp | tail -1 | tr -d '\n')/tools/hxcpp
haxe compile.hxml
