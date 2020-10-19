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

using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]
public class PostProcessingStack : MonoBehaviour
{
    [System.Serializable]
    public class PostProc
    {
        public Material mtl;
        public int[] sourceBufferIndices = new int[0];
        public int targetBufferIndex = -1;
    };

    [System.Serializable]
    private class BufferInfo
    {
        public int factorX = 1;
        public int factorY = 1;
        public RenderTextureFormat format = RenderTextureFormat.ARGBHalf;
    }

    [SerializeField] private BufferInfo[] bufferFactors = new BufferInfo[0];

    [SerializeField] public PostProc[] stack = new PostProc[1];

    private RenderTexture[] _buffers = new RenderTexture[0];

    private void Awake()
    {
        #if UNITY_EDITOR
        if (Application.isPlaying)
        #endif
        {
            foreach (PostProc process in stack)
                process.mtl = Instantiate(process.mtl);
        }
        
        _camera = GetComponent<Camera>();
        _camera.depthTextureMode |= DepthTextureMode.Depth;
        _cameraTransform = _camera.transform;
    }

    private int _w0;
    private int _h0;
    private Camera _camera;
    private Transform _cameraTransform;

    void OnEnable()
    {
        if (Screen.width < 64 || Screen.height < 64)
            return;
        _w0 = Screen.width;
        _h0 = Screen.height;
        _buffers = new RenderTexture[bufferFactors.Length];
        for (int i = 0; i < bufferFactors.Length; ++i)
            _buffers[i] = new RenderTexture(
                Screen.width / bufferFactors[i].factorX,
                Screen.height / bufferFactors[i].factorY,
                1,
                bufferFactors[i].format);
    }

    private readonly Vector3[] _frustumCornersA = new Vector3[4];
    private Matrix4x4 _frustumCorners = Matrix4x4.identity;
    private Matrix4x4 _prevVP;
    private static readonly int uFrustumCorners = Shader.PropertyToID("uFrustumCorners");
    private static readonly int uPrevWorldToCameraMatrix = Shader.PropertyToID("uPrevWorldToCameraMatrix");
    private int _frame;
    private static readonly int frame = Shader.PropertyToID("_Frame");

    void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        ++_frame;
            
        if (Screen.width != _w0 || Screen.height != _h0)
            OnEnable();

#if UNITY_EDITOR
        if (!Application.isPlaying && _buffers.Length != bufferFactors.Length)
            OnEnable();
#endif
        
        _camera.CalculateFrustumCorners(new Rect(0, 0, 1, 1), 1.0f, Camera.MonoOrStereoscopicEye.Mono, _frustumCornersA);
        _frustumCorners.SetRow(0, _cameraTransform.TransformVector(_frustumCornersA[0]));
        _frustumCorners.SetRow(1, _cameraTransform.TransformVector(_frustumCornersA[3]));
        _frustumCorners.SetRow(2, _cameraTransform.TransformVector(_frustumCornersA[1]));
        _frustumCorners.SetRow(3, _cameraTransform.TransformVector(_frustumCornersA[2]));
        
        foreach (PostProc process in stack)
        {
            for (int j = 0; j < process.sourceBufferIndices.Length; ++j)
            {
                RenderTexture colorBuffer = process.sourceBufferIndices[j] == -1 ? src : _buffers[process.sourceBufferIndices[j]];
                process.mtl.SetTexture($"uImage{j}", colorBuffer);
            }
            
            process.mtl.SetMatrix(uFrustumCorners, _frustumCorners);
            process.mtl.SetMatrix(uPrevWorldToCameraMatrix, _prevVP);
            process.mtl.SetInt(frame, _frame);
            
            RenderTexture target = (process.targetBufferIndex == -1) ? dst : _buffers[process.targetBufferIndex];
            Graphics.Blit(null, target, process.mtl);
        }

        _prevVP = _camera.projectionMatrix * _camera.worldToCameraMatrix;
    }
}