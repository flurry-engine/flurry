#!/bin/bash

npx haxe build.hxml -D reporter=XUnit2Reporter -D report-name=Engine-Tests-$AGENT_OS --debug --no-traces
./bin/Main-debug
