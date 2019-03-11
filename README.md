# Flurry

[![Build Status](https://dev.azure.com/flurry-engine/flurry/_apis/build/status/flurry-engine.flurry?branchName=master)](https://dev.azure.com/flurry-engine/flurry/_build/latest?definitionId=3&branchName=master)

This engine is currently WIP so nothing is set in stone or stable.

Flurry is a cross platform, 2D focused game engine written in the Haxe language. It currently supports Windows, Mac, and Linux with many more targets planned down the road.

The engine is heavily inspired by the [luxe engine (haxe alpha version)](https://github.com/underscorediscovery/luxe) by Sven Bergström with much of the terminology and code acting as the base or in many cases directly copied over. Anyone familiar with luxe will find flurry extremely familiar, most of the stuff I have changed and am planning to change is under the hood so the user api should say fairly similar to luxe.

Flurry is primarily for my own use and learning experience, but if anyone else finds it useful then that's great as well!

## Features

* Multiple Rendering Backends
    - OpenGL 4.5 backend takes use of persistently mapped buffers, bindless textures, SSBOs, and many other modern OpenGL techniques (Windows and Linux)
    - Directx 11 (Windows).
    - WebGL / GLES backend is a fallback for very old hardware, OSX, and web targets (Windows, Mac, and Linux).

* First Class Shader Support
    - GLSL and HLSL shaders are fully supported.
    - You currently have to write shaders by hand for each backend but this is planned to be automated by spriv-cross.
    
* Batched Drawing
    - Geometries are batched together to minimise draw calls.
    - You can also directly upload data to the GPU if you want to skip the geometry and batching process and do it yourself.

* SAT 2D collision detection provided by [differ](https://github.com/snowkit/differ).

* Built in support for [dear imgui](https://github.com/ocornut/imgui/) for quick debug menu creation.

## Planned Features

* Kha Target
    - Planning to add a kha backend along side snow, this will allow the engine to reach many more devices quicker than if I were to do it all myself.
    
* Vulkan Backend
    - A Vulkan backend is planned, MoltenVK could be used to give the Mac better performance than just GLES.
    
* Other Stuff
    More planned features can be found on the project page https://github.com/Aidan63/Flurry/projects/1

## Old Screenshots

![WIP Game Project](resources/gpu2.gif)

![Provided Sample Project](resources/gpu1.gif)
