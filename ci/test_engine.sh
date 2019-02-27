#!/bin/bash

cd test

haxe build.hxml -D reporter=XUnit2Reporter -D report-name=Engine-Tests-$AGENT_OS

if [ $AGENT_OS == 'Windows_NT' ]; then
    ./bin/Main.exe
else
    ./bin/Main
fi
