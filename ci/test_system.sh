#!/bin/bash

cd tests/system

sudo Xvfb :99 -screen 0 768x512x24 &
export DISPLAY=:99

haxe -L buddy -L format -D reporter=XUnit2Reporter -D report-name=System-Tests-$AGENT_OS --debug --run Test