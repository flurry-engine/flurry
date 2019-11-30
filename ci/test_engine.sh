#!/bin/bash

cd tests/unit

npx haxe build.hxml -D reporter=XUnit2Reporter -D report-name=Engine-Tests-$AGENT_OS --debug --no-traces

if [ $AGENT_OS == 'Windows_NT' ]; then
    ./bin/Main-debug.exe
else
    ./bin/Main-debug
fi
