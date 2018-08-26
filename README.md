# GPU Renderer

This repo contains a little GPU renderer mainly designed around 2D games. Geometry is batched together and sorted to try and minimise state changes for better performance. Currently included is a GL4.5 backend, a Directx 11 backend, and a backend built on snow's WebGL haxe class. This class allows the WebGL backend to work on native and web targets (Web targets are pretty much untested right now).

Mainly created for my own personal use and learning experience, but others might find it useful as well. Wasn't sure what to call it so GPU will do for now!

![WIP Game Project](resources/gpu2.gif)

![Provided Sample Project](resources/gpu1.gif)

## Info

* Multiple Rendering Backends
    - OpenGL 4.5 backend takes use of persistently mapped buffers, bindless textures, SSBOs, and many other modern OpenGL techniques. This backend should be the fastest but also least supported (OSX and many intel iGPUs do not have OpenGL 4.5 support, AMDs Windows GL driver is also really bad).
    - Directx 11 will give good performance to pretty much all hardware on windows.
    - WebGL backend is a fallback for very old hardware, OSX, and web targets.

* WIP
    - Renderer is very much a work work in progess.
    - CPU is the limiting factor right now, basically no checks are done before doing transformations, sorting, etc.

* OpenGL and DirectX
    - My OpenGL and DirectX bindings can be found below. My linc_opengl fork must be used right now as the changes I've made have not yet been merged into the main repo. linc_opengl bindings must also be built with GL_ARB_bindless_texture support. See `build.hxml` in the `gen` directory for info on adding that.
    - [linc_opengl](https://github.com/aidan63/linc_opengl)
    - [linc_directx](https://github.com/Aidan63/linc_directx)

* Sample Project Provided
    - This repos sample directory contains a basic little snow based program showing you how to get stuff on the screen. The API is heavily inspired by luxe so anyone familiar with that should have no problem getting started.
    - More documentation, tests, and samples will be added over time.

## General Renderer TODO:

* Batcher sorting.
    - Each batcher stores all its geometries in an array and before drawing the batcher will do a merge sort on the array. This is very expensive with lots of geometry and usually unneeded. The geometry list should only be sorted when the geometries properties change.
    - A self balancing BST could be utilised in the same way luxe does. When a geometry wants to change a property it is removed from its batchers, the properties are set, then its re-inserted.

* Batcher Vertex Buffers
    - Currently each batcher has its own vertex buffer which geometry data is transformed and stored into. This buffer is then passed to the backend where it is copied into the backends own vertex buffer.
    - This extra copying can be skipped by having the batcher be provided a vertex buffer to write into. In the GL45 and DX11 backend case this would be its mapped buffers, and in WebGL just a client side buffer.

* Anti-Aliasing
    - Options should be provided to set how much MSAA to apply to the renderer

* Remove Snow Dependency
    - Currently relies on snow for Float32Array and getting the current display size. Haxe provides its own Float32Array and options should be created to allow specifying the display size.
    - WebGL backend possible issue. By using snow and its typed arrays we get a native and a web backend in a single file through WebGL.hx. When targeting the web snow buffers become native js types allowing for perfect interop with webgl. Haxe typed arrays differ from js and are not externs on web targets.
    - Possible option is to take snow buffers and put them into their own repo.
    - Buddy tests would no longer need to run under snow due to the buffer requirements.

* Separation of Shaders and their Uniforms
    - Separating shaders and their uniform values would allow the backends to update the shaders and uniforms separately when possible.

* Controllable Batcher
    - The renderer backend should be able to specify how the draw commands are generated and what data is included. Eg. It might be more performant for backends which have multi draw indirect functionality (GL 4.5, Vulkan) to do model transformations on the GPU instead of CPU. With bindless texture support breaking batches on texture changes is no longer needed.
    - Could also allow backends to specify to the bactchers to update the commands uniforms with a view and projection matrix instead of them included in the draw command. This would avoid the need of any "default" renderer uniforms and allow split screen functionality.

* Texture Data
    - Texture data is not currently updatable beyond its creation or being used as a render target. Being able to get and set texture data with an array of unit8s would be useful.

* Pre-Compiled Shaders
    - The create shader function or should contain a pre-compiled flag. This would allow the DX11 and GL / Vulkan backends to skip shader compilation.

* Custom Vertex Layout
    - All Geometry is currently passed to shaders and POSITION, COLOUR, TEXCOORD. The shader layout definition could contain an extra array for custom vertex layouts.
    - Vertex texcoords should be able to hold multiple texcoords so the layout can reference them. There should also be some sort of generic data storage for user defined per vertex data.

## WebGL Backend TODO:
* Static Geometry
    - Unchanging flag is currently ignored. A separate buffer or section of the buffer (same as gl 4.5 backend) could be used.
* Core GL Profile Support
    - On native targets the webGL backend will not run if the user specifies a core profile. This is probably due to the fact that core profiles require at least one VAO. This should be fixed for native platforms as compatibility profiles shouldn't be used (Many vendors only support core profiles or compatibility support is very low).
* Ensure web targets are working.

## OpenGL 4.5 Backend TODO:
* Nothing Planned

## DirectX 11 Backend TODO:
* Static Geometry
    - Unchanging flag is currently ignored. A separate buffer or section of the buffer (same as gl 4.5 backend) could be used.

## Vulkan Backend TODO:
* No Work Started
    - Vulkan bindings need to be created for haxe.
    - New linc_opengl bindings generator which reads from the official khronos registry could be adapted to easily create vulkan bindings.
    - MoltenVK would allow this backend to work on OSX. Better performance and wouldn't rely on the now deprecated GL.

## Other Work

* Maths Listeners
    - Add optional listener functions for the maths classes. Allows easy creation of dirty flags for other renderer parts.

* Camera Matrices
    - Camera currently recalculates it matrices each step. Dirty flag should be added to know when to recalulate. Relies on Matrix and Vector listeners.

* Fonts / Text
    - Multi page support for bitmaps
    - Bounding box for text
    - Bitmaps font size

* Transformation
    - move transformation into the maths section as it could be more useful in other non gpu cases
    - add dirty flag so the transformation is not needlessly calculated

* Tests
    - Much work has been done since the renderer tests were created. Should be updated to reflect the current state of the renderer.