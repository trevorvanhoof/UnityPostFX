# UnityPostFX
Unity 5 / legacy render pipeline post FX for when you want to skip the post processing stack
(tested in at least 2019.3.14f1)

## Requirements
Use **HDR** render targets.

It is recommended to use **linear** space 

#### Using gamma space
Alternatively there is an "srgb2lin" effect at the end of the default "Main Camera"
prefab that can be moved to the top of the stack instead to have an identical
post processing pipeline applied to a gamma space camera source.

If we omit the "grading" and "srgb2lin" effects and tweak the "bloom" effect (by eye) it will 
look reasonable in gamma space.

## Features
Works in both forward and deferred.

Customizable post processing stack

    Fine grained control of the entire stack and the render textures
    used (ability to optimize render texture usage by hand).
    The editor is not clever / user friendly, but you **can** achieve
    fairly complex render graphs with it as perhaps demonstrated by
    the included "Main Camera" prefab.

Multi-layer 'bloom' & lens-dirt pass

    This elaborate bloom is the meat of the "Main Camera" prefab:
    We do a downsample -> horizontal blur -> vertical blur
    to get a cheap seperable guassian blur of the scene.
    We then *repeat* this about 6 times to get a super soft bloom.
    Finally the bloom material weights all these textures with a
    customizable amount of bloom and dirt.

Cheap ACES tone mapping curve & srgb 'grading' pass.

'Fxaa3' pass 

    Operates on srgb target, hence the grading pass outputting srgb.
    The results are more crisp than Unity's post processing stack 
    fxaa3 (which loses more thin lines by blurring more).

'srgb2lin' pass 

    When using linear space unity expects our camera to return a linear buffer

**Please** look in PostFX/ and play with materials matching the aforementioned 'pass' names to get the most out of things.

#### Bonus
Includes an aliasing hell scene for fun. For this I added a simple grass vertex/surface shader and a *very bright* shader that you may enjoy.

Fog effect to use old-school fog in deferred render pipeline.

    See window->rendering->lighting settings to set the 
    fog color and density, it is required to 'enable' fog 
    and 'mode' must be 'exponential' to avoid undefined behavior.
    
    This will not work well with transparent objects, but I've
    made good use of this post effect nonetheless. 

## License
MIT License

Copyright (c) 2020 Trevor van Hoof
    
    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:
    
    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.
    
    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.

MIT licensed hash44 (C) 2014 Dave Hoskins
https://www.shadertoy.com/view/4djSRW

MIT licensed smooth value noise (C) 2013 Inigo Quilez
https://www.shadertoy.com/view/lsf3WH 

MIT licensed ACES tone mapping (C) 2016 Krzysztof Narkowicz
https://knarkowicz.wordpress.com/2016/01/06/aces-filmic-tone-mapping-curve/

Public domain FXAA (C) 2009 Timothy Lottes
https://developer.download.nvidia.com/assets/gamedev/files/sdk/11/FXAA_WhitePaper.pdf
I preprocessed and minified public domain source code by Tomothy Lottes from:
https://gist.github.com/kosua20/0c506b81b3812ac900048059d2383126

WTFPL License Hsv to rgb and rgb to hsv conversions (c) 2013 Sam Hocevar
http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl

Linear to sRGB and sRGB to linear conversions (C) 2012 Ian Taylor
from http://chilliant.blogspot.com/2012/08/srgb-approximations-for-hlsl.html

## Future work
Better temporal stability AA, although I don't want to look into motion vector solutions
so it'll be some kind of short-history and camera-motion only solution. Possibly
reprojecting only 1 frame with a smart dither.

Sharpen effect.

#### Longer term
We can add all kinds of wacky post effects like vignettes and film grains,
or high-end ones such as good SSAO, SSR and (volumetric) height fog.
These are all really complicated problems though so... not likely to happen.
