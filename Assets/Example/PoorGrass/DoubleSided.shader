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

Some normal manipulation shader tricks sourced from Ben Golus answering similar questions on the Unity forums:
https://forum.unity.com/threads/world-space-to-tangent-space.504575/ 
https://github.com/bgolus/Normal-Mapping-for-a-Triplanar-Shader/blob/master/TriplanarSurfaceShader.shader

A relatively poor grass shader that does the following:
> Poor man's vertex wiggle based on object world position
> Random tint based on object world position
> Take the view-space normal and absoluet the Z component to never have back-facing normals
  but mirror them in a natural way instead of straigh-up inverting them so back faces still look different.
  It sounds odd but it makes the field look much brighter / closer to it's albedo.
 
Requires instancing and NOT static batching!

Not recommened for production, use a properly optimized vertex / fragment shader,
especially the normal trick does a ton of matrix math that is necessarily only because
surface shaders are locking us out of doing optimized things. 
*/
Shader "Custom/DoubleSided"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
    }
    SubShader
    {
        Cull Off
        
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float3 tint;
            float2 uv_MainTex;
            float3 worldNormal;
            INTERNAL_DATA
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)
       
        void vert (inout appdata_full v, out Input o) 
        {
            float2 worldPos = unity_ObjectToWorld._m03_m23 * 2.0;
            float2 offset = sin(worldPos + dot(worldPos, cos(worldPos.yx)) + _Time.ww) * v.vertex.y * 0.1;
            v.vertex.xyz += mul((float3x3)unity_WorldToObject, float3(offset.x,0,offset.y));
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.tint = lerp(float3(1.0, 1.0, 0.5), float3(0.5, 1.0, 1.0), sin(worldPos.x * 432.197) * 0.5 + 0.5);
        }
        
        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // work around bug where IN.worldNormal is always (0,0,0)!
            IN.worldNormal = WorldNormalVector(IN, float3(0,0,1));
            
            // work around bug where I mesesd up the quad rotation and need to flip the original normal
            if(IN.worldNormal.y < 0.0)
                IN.worldNormal = -IN.worldNormal;
                        
            // Get world to tangent space matrix
            float3 t2w0 = WorldNormalVector(IN, float3(1,0,0));
            float3 t2w1 = WorldNormalVector(IN, float3(0,1,0));
            float3 t2w2 = WorldNormalVector(IN, float3(0,0,1));
            float3x3 t2w = float3x3(t2w0, t2w1, t2w2);
            
            // view-space mirror Z so normal always faces the camera
            float3 tmp = mul(IN.worldNormal, (float3x3)UNITY_MATRIX_V);
            tmp.z = abs(tmp.z);
            // project back to tangent space for output
            tmp = mul((float3x3)UNITY_MATRIX_V, tmp);
            tmp = mul(t2w, tmp);
            
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb * IN.tint;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Normal = normalize(tmp);
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
