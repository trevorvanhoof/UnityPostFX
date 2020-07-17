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
            
			uniform sampler2D _CameraDepthTexture;
            uniform sampler2D uImage0;
            uniform float4 uFogColor;
            uniform float uFogDensity;
            uniform float uNear;
            uniform float uFar;
            
            float ComputeFogDistance(float depth)
            {
                float dist = depth * uFar;
                dist -= uNear;
                return dist;
            }
            
            half ComputeFog(float z)
            {
                // Only supporting exponential fog
                return saturate(exp2(-uFogDensity * z));
            }

            float4 frag(v2f i) : SV_Target
            {
                half4 color = tex2D(uImage0, i.uv);
                
                float depth = tex2D(_CameraDepthTexture, i.uv ).r;
                depth = Linear01Depth(depth);
                
                float skybox = depth < 0.999999 && color.a > 0.0;
                float dist = ComputeFogDistance(depth);
                half fog = 1.0 - ComputeFog(dist);
    
                return lerp(color, uFogColor * uFogColor * 1.2, fog * skybox);
            }
            ENDCG
        }
    }
}
