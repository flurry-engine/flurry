#!/bin/bash

cd tests/unit

haxe build.hxml -D reporter=XUnit2Reporter -D report-name=Engine-Tests-$AGENT_OS --debug

if [ $AGENT_OS == 'Windows_NT' ]; then
    ./bin/Main-debug.exe
else
    ./bin/Main-debug
fi
