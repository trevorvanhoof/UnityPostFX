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

This is the meat of it all!

    bufferFactors
First you need to define buffers to render into:
The factor is a fraction of the screen size, so to render at half-resolution
just enter factorX = 2 and factorY = 2.

The texture format speaks for itself, when planning post effects
check which post effects require / benefit from HDR render targets
and give all targets used up until the last HDR effect R11G11B10 Float or RGBA Half targets
(going from less bits to more bits generally isn't very productive, generally).

    stack
Next you can fill out your post processing stack. Each process is executed in order.
Specify a material that will be used to render a screen-space quad.
Specify source buffer indices, these are array indices into the bufferFactors array.
-1 is the screen's buffer.

Last specify the target buffer. As soon as we encounter an effect targeting "-1" (the screen)
the loop is stopped, this way you can enter -1 as target in any pass to view the 
output up to that point in the stack.
*/

using UnityEngine;

[ExecuteInEditMode]
public class PostProcessingStack : MonoBehaviour
{
    [System.Serializable]
    public class PostProc
    {
        public Material mtl = null;
        public int[] sourceBufferIndices = new int[0];
        public int targetBufferIndex = -1;
    };

    [System.Serializable]
    class BufferInfo
    {
        public int factorX = 1;
        public int factorY = 1;
        public RenderTextureFormat format = RenderTextureFormat.ARGBHalf;
    }

    [SerializeField] BufferInfo[] bufferFactors = new BufferInfo[0];

    [SerializeField] public PostProc[] stack = new PostProc[1];

    RenderTexture[] buffers = new RenderTexture[0];

    void Awake()
    {
        if (Application.isPlaying)
        {
            for (int i = 0; i < stack.Length; ++i)
            {
                stack[i].mtl = Instantiate(stack[i].mtl);
            }
        }
    }

    private int w0;
    private int h0;

    void OnEnable()
    {
        if (Screen.width < 64 || Screen.height < 64)
            return;
        w0 = Screen.width;
        h0 = Screen.height;
        buffers = new RenderTexture[bufferFactors.Length];
        for (int i = 0; i < bufferFactors.Length; ++i)
            buffers[i] = new RenderTexture(
                Screen.width / bufferFactors[i].factorX,
                Screen.height / bufferFactors[i].factorY,
                1,
                bufferFactors[i].format);
    }

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        if (Screen.width != w0 || Screen.height != h0)
            OnEnable();

#if UNITY_EDITOR
        if (!Application.isPlaying && buffers.Length != bufferFactors.Length)
            OnEnable();
#endif

        for (int i = 0; i < stack.Length; ++i)
        {
            for (int j = 0; j < stack[i].sourceBufferIndices.Length; ++j)
            {
                if (stack[i].sourceBufferIndices[j] == -1)
                {
                    stack[i].mtl.SetTexture(string.Format("uImage{0}", j), src);
                }
                else
                {
                    stack[i].mtl.SetTexture(string.Format("uImage{0}", j), buffers[stack[i].sourceBufferIndices[j]]);
                }
            }

            RenderTexture tmpDst = (stack[i].targetBufferIndex == -1) ? dst : buffers[stack[i].targetBufferIndex];
            if (tmpDst == null)
            {
                stack[i].mtl.SetVector("uResolution", new Vector4(Screen.width, Screen.height, 1.0f / Screen.width, 1.0f / Screen.height));
            }
            else
            {
                stack[i].mtl.SetVector("uResolution", new Vector4(tmpDst.width, tmpDst.height, 1.0f / tmpDst.width, 1.0f / tmpDst.height));
            }

            Graphics.Blit(
                null,
                tmpDst,
                stack[i].mtl);

            if (stack[i].targetBufferIndex == -1)
                return;
        }
    }
}