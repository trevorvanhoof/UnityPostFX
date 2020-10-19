/*
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

Multi-layer bloom, it just blends a ton of inputs that are assumed to be
more and more blurry versions of the original image. This is currently all
handled by many different shaders in the PostProcessingStack on our camera,
but perhaps in the future this should be a compute shader that just processes
the screen into 1 mip-chain directly. I don't have the skill to optimize
that to be worthwhile though, so... enjoy these visuals 
if you have performance budget for it?

Parameter description:

uImage0: The original image
uImage1: Downsample uImage to original resolution / 2 (so a quarter of the total size) and blur
uImage2: Downsample uImage1 & repeat, resulting in original resolution / 4
uImage3: Repeat with uImage2, original resolution / 8
uImage4: Repeat with uImage3, original resolution / 16
uImage5: Repeat with uImage4, original resolution / 32
uImage6: Repeat with uImage5, original resolution / 64

All these images [1, 6] are then added together using uBloomWeights
to fade them in and out, based on your style you may want to start out
with all weights = 1, or all weights getting quadratically smaller (1, 1/2, 1/4, 1/8, etc)
for a tighter bloom (works better at low bloom amounts). 

uLensDirt: Lens dirt texture, we multiply the resulting bloom stack with this texture.
uLensDirtAmount: Fade the amount of lens dirt we apply, 0 means lens dirt texture is ignored.
uBloom: After selecting lens dirt amount, we fade the original image with the result by this amount, 0 means no bloom.
*/
Shader "Hidden/bloom"
{
    Properties
    {
		uLensDirt ("Lens dirt", 2D) = "white" {}
		uLensDirtAmount ("Dirt amount", Range(0, 1)) = 0.5
		uBloom ("Bloom amount", Range(0, 1)) = 0.04
		
		uBloomWeights ("BloomWeights 1-4", Vector) = (1.0, 1.0, 1.0, 1.0)
		uBloomWeights2 ("BloomWeights 5-6", Vector) = (1.0, 1.0, 1.0, 1.0)
    }
    
    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            uniform sampler2D uImage0;
            uniform sampler2D uImage1;
            uniform sampler2D uImage2;
            uniform sampler2D uImage3;
            uniform sampler2D uImage4;
            uniform sampler2D uImage5;
            uniform sampler2D uImage6;
            
			uniform sampler2D uLensDirt;
			uniform float uBloom;
			uniform float uLensDirtAmount;
			
            uniform float4 uBloomWeights;
            uniform float2 uBloomWeights2;

            float4 frag(v2f i) : SV_Target
            {
                float4 c = tex2D(uImage1, i.uv) * uBloomWeights.x +
					tex2D(uImage2, i.uv) * uBloomWeights.y +
					tex2D(uImage3, i.uv) * uBloomWeights.z +
					tex2D(uImage4, i.uv) * uBloomWeights.w +
					tex2D(uImage5, i.uv) * uBloomWeights2.x +
					tex2D(uImage6, i.uv) * uBloomWeights2.y;
				float totalWeight = uBloomWeights.x + uBloomWeights.y + uBloomWeights.z + uBloomWeights.w +  uBloomWeights2.x + uBloomWeights2.y;
				c /= max(0.001, totalWeight);
                c *= lerp((1.0).xxxx, tex2D(uLensDirt, i.uv), uLensDirtAmount);
                return lerp(tex2D(uImage0, i.uv), c, uBloom);
            }
            ENDCG
        }
    }
}
