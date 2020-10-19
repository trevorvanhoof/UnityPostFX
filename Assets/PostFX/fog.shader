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

Unity doesn't support depth fog in the deferred render pipeline, I've decided
to add just the exponential fog with the caveat that it will indeed act weird
on transparent objects as it is based solely on the final pixel depth, which
is wrong in any event. It still worked for my use cases though.

See window->rendering->lighting settings to set the fog color and density,
it is required to enable fog and mode must be exponential to avoid undefined behavior. 
*/
Shader "Hidden/fog"
{
    Properties
    {
        uFogColor ("Fog color", Color) = (0,0,0,0)
        uFogCube ("Fog cube", Cube) = "black" {}
        uFogDensity ("Density, Linear start, Linear end", Vector) = (0.01, 1.0, 100.0, 0.0)
        [KeywordEnum(Linear, Exponential, Exponential Squared, Pow fit)] uFogMode ("Mode", Int) = 0
    }

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM
            #pragma multi_compile_local UFOGMODE_LINEAR UFOGMODE_EXPONENTIAL UFOGMODE_EXPONENTIAL_SQUARED UFOGMODE_POW_FIT
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

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            uniform sampler2D _CameraDepthTexture;
            uniform sampler2D uImage0;
            uniform float4 uFogColor;
            uniform float4x4 uFrustum;
            uniform samplerCUBE uFogCube;
            #ifdef UFOGMODE_LINEAR
            uniform float3 uFogDensity;
            #else
            uniform float uFogDensity;
            #endif

            uniform float4x4 uFrustumCorners;

            half ComputeFog(float z)
            {
        #ifdef UFOGMODE_POW_FIT
                return pow(Linear01Depth(z), uFogDensity.x);
        #else
                z = LinearEyeDepth(z) - _ProjectionParams.y;
            #ifdef UFOGMODE_LINEAR
                return saturate(1.0 - ((z - uFogDensity.y) / (uFogDensity.z - uFogDensity.y)));
            #endif
            #ifdef UFOGMODE_EXPONENTIAL
                return saturate(exp2(-uFogDensity * z));
            #endif
            #ifdef UFOGMODE_EXPONENTIAL_SQUARED
                return saturate(exp2(-uFogDensity * z * z));
            #endif
        #endif
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 rayDirection = lerp(lerp(uFrustumCorners[0], uFrustumCorners[1], i.uv.x),
                                           lerp(uFrustumCorners[2], uFrustumCorners[3], i.uv.x), i.uv.y);
                float4 skyColor = texCUBE(uFogCube, rayDirection);
                half4 color = tex2D(uImage0, i.uv);
                float depth = tex2D(_CameraDepthTexture, i.uv).r;
                float skybox = depth != 0.0;
                half fog = max(0.0, 1.0 - ComputeFog(depth));
                return lerp(color, skyColor + uFogColor, fog * skybox);
            }
            ENDCG
        }
    }
}