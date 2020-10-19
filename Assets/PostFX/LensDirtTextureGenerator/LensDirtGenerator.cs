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

Basic editor utility to generate textures from shaders.

Blit a material to a temporary render texture, copy again to Texture2D and
save as PNG. Deletes existing file beforehand.

The texture is included so feel free to omit this file.
*/
#if UNITY_EDITOR

using System.IO;
using UnityEngine;

[ExecuteInEditMode]
public class LensDirtGenerator : MonoBehaviour
{
    [SerializeField] private bool cook = false;
    [SerializeField] private Material mtl = null;
    [SerializeField] private int width = 1920;
    [SerializeField] private int height = 1080;
    [SerializeField] private string path = "Assets/PostFX/lensdirt.png";

    void Update()
    {
        if (!cook)
            return;
        cook = false;

        // open render ctx
        RenderTexture tmp = RenderTexture.GetTemporary(width, height, 0, 
            RenderTextureFormat.ARGB32, RenderTextureReadWrite.sRGB, 4);
        var prev = RenderTexture.active;
        RenderTexture.active = tmp;

        // render
        Graphics.Blit(null, tmp, mtl);

        // to texture
        Texture2D tex = new Texture2D(width, height, TextureFormat.ARGB32, false);
        tex.ReadPixels(new Rect(0, 0, width, height), 0, 0);

        // close render ctx
        RenderTexture.active = prev;
        RenderTexture.ReleaseTemporary(tmp);

        // (re-)save texture
        if (File.Exists(path))
            File.Delete(path);
        File.WriteAllBytes(path, tex.EncodeToPNG());
    }
}
#endif