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

hash44 from https://www.shadertoy.com/view/4djSRW
(C) 2014 Dave Hoskins, MIT licensed

smooth value noise from https://www.shadertoy.com/view/lsf3WH
(C) 2013 Inigo Quilez, MIT licensed 

Generate a procedural lens dirt texture with a bunch of circles, hexagons and tori
to look like a dirty lens when multiplied in the bloom pass. Using a procedural
texture avoids having to license a picture.

The texture is included so feel free to omit this file.
*/
Shader "Hidden/lensdirtgen"
{
    Properties { _ScreenParams ("_ScreenParams", Vector) = (1280, 720, 0, 0) }
    
    SubShader
    {
        // No culling or depth
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
            
#define vec2 float2
#define vec3 float3
#define vec4 float4
#define fract frac
#define mix lerp

// hash44 from https://www.shadertoy.com/view/4djSRW
// (C) 2014 Dave Hoskins, MIT licensed
vec4 hash4(vec4 p4){p4 = fract(p4 * vec4(.1031, .1030, .0973, .1099));p4 += dot(p4, p4.wzxy + 19.19);return fract((p4.xxyz + p4.yzzw) * p4.zywx);}
vec2 hash2(float p){return hash4(vec4(p,p,p,p)).xy;}
float hash1(float p){return hash4(vec4(p,p,p,p)).x;}

// smooth value noise from https://www.shadertoy.com/view/lsf3WH
// (C) 2013 Inigo Quilez, MIT licensed 
float snoise(vec2 x)
{
    vec2 p = floor(x);
    vec2 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float n = p.x + p.y * 157.0;
    return mix(mix(hash1(n), hash1(n + 1.0), f.x), mix(hash1(n + 157.0), hash1(n + 158.0), f.x), f.y);
}

float perlin(vec2 p, int iterations)
{
	float f = 0.0;
	float amplitude = 1.0;

	for (int i = 0; i < iterations; ++i)
	{
		f += snoise(p) * amplitude;
		amplitude *= 0.5;
		p *= 2.0;
	}

	return f * 0.5;
}

float cub(float f){return f*f*f;}
float2 rotate2D(float2 uv, float angle)
{
return cos(angle)*uv+sin(angle)*float2(uv.y,-uv.x);
}
#define PI 3.14159265359
float sqr(float f){return f*f;}
float hexagon(vec2 uv, float rad)
{
// symmetry
uv = abs(uv);
// create a diamond shape (just a triangular diagonal)
float result = dot(uv, float2(sqrt(0.75), 0.5));
// finish the shape by limitting the top point of the triangle to create a quater hex
result = max(result, uv.y);
// subtract the radius so it's easier to step(0.0, result) later
return result - rad;
}

// I think this originates from
// http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
// WTFPL License Hsv to rgb and rgb to hsv conversions (c) 2013 Sam Hocevar
vec3 hsv2rgb(vec3 c){return c.z*mix(vec3(1,1,1),saturate(abs(fract(vec3(1,2/3.,1/3.)+c.x)*6-3)-1),c.y);}
vec3 hsv2rgb(float h, float s, float v){return hsv2rgb(vec3(h,s,v));}

            fixed4 frag (v2f i) : SV_Target
            {
            vec2 gl_FragCoord = i.uv * _ScreenParams;
    vec2 uv = (gl_FragCoord.xy * 2.0 - _ScreenParams)/_ScreenParams.y;

    vec2 x = uv;
    float v = 2.0 * perlin(x * 16.0 + snoise(x * 8.0), 8);
    v += perlin(x * 16.0 + snoise(x * 16.0), 8);
    v *= 0.35;

    vec3 a = (0.0);
    for(int i=0;i<1000;++i){
        float r = cub(hash1(i*2.2-1000)+.2)*.1+.05;
        vec2 c = uv-(hash2(i*.8+2000)*4.-2.);
        float d;
        if(hash1(i*.22 + 1500)>0.8)
        {c=rotate2D(c, hash1(i));
            d = -hexagon(c, r);}
        else
            d = r - length(c);
        if(hash1(i*.12+40)>0.75)
            d = (r * 0.1 - abs(d))*2;
        vec4 cl = hash4(i);
        a += saturate(d*(30 + 30 * hash1(i*PI-2000))) * hsv2rgb(vec3(fract(cub(cl.x*0.8)+0.1), cl.y * cl.z * 0.6, cl.w*sqr(cl.w) / (0.5 + r * 80.0)));
    }

    return vec4(a,1.0) + pow(v, 8.0) + vec4(0.0, 0.01, 0.05, 0.0) * (0.5 - 0.5 * uv.y) + vec4(0.02, 0.0, 0.01, 0.0) * (0.5 - 0.5 * uv.x);
            }
            ENDCG
        }
    }
}
