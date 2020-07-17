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

This is a super basic resampler that just takes 4 taps and averages them for the
poor-man's MSAA implementation. It does not scale beyond MSAA4 (resolutionScale = 2)
but smaller sizes (like 2) are well worth the visual quality increase.
*/
using UnityEngine;

[ExecuteInEditMode, RequireComponent(typeof(Camera))]
public class ResolutionOverride : MonoBehaviour
{
    private RenderTexture cache = null;
    private RenderTexture restore = null;
    new private Camera camera = null;
    public float resolutionScale = 1.0f;
    [SerializeField] private Material resample = null;
    
    void OnEnable()
    {
        camera = GetComponent<Camera>();
    }

    private void OnPreRender()
    {
        restore = camera.targetTexture;
        int w = (int) (Screen.width * resolutionScale);
        int h = (int) (Screen.height * resolutionScale);
        if (cache == null || cache.width != w || cache.height != h)
            cache = new RenderTexture(w, h, 24, RenderTextureFormat.ARGBHalf);
        camera.targetTexture = cache;
    }

    void OnPostRender()
    {
        camera.targetTexture = restore;
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        float denom = Mathf.Abs(1.0f / resolutionScale - 1.0f);
        resample.SetVector("uRcp", new Vector4(denom / Screen.width, denom / Screen.height));
        resample.SetTexture("uImage0", src);
        Graphics.Blit(null, dst, resample);
    }
}
