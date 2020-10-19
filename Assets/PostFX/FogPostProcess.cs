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

Applies the fog shader in deferred. If the camera is forward, we disable
this script to avoid applying fog twice.

It forces the camera to render depth. I'm a bit fuzzy on what happens if
you already enabled depthNormal, and whether the fog shader still works in that case.
*/
using UnityEngine;

[ExecuteInEditMode]
public class FogPostProcess : MonoBehaviour
{
    public Material mtl;
    private void Start()
    {
        Camera cam = GetComponent<Camera>();
        
        // We are not needed in forward rendering!
        if (cam.renderingPath == RenderingPath.Forward)
        {
            enabled = false;
            return;
        }

        cam.depthTextureMode |= DepthTextureMode.Depth;
    }
    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        // Unity Fog doesn't work in deferred so I took a shot at implementing exponential fog.
        Camera cam = GetComponent<Camera>();
        mtl.SetTexture("uImage0", src);
        mtl.SetColor("uFogColor", RenderSettings.fogColor);
        mtl.SetFloat("uFogDensity", RenderSettings.fogDensity);
        Graphics.Blit(src, dst, mtl);
    }
}
