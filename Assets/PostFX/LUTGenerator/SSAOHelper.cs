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
*/

#if UNITY_EDITOR

using System.Collections.Generic;
using System.IO;
using UnityEngine;

public static partial class ExtensionMethods
{
    // https://stackoverflow.com/questions/273313/randomize-a-listt
    private static System.Random rng = new System.Random();

    public static void Shuffle<T>(this IList<T> list)
    {
        int n = list.Count;
        while (n > 1)
        {
            n--;
            int k = rng.Next(n + 1);
            T value = list[k];
            list[k] = list[n];
            list[n] = value;
        }
    }
}

[ExecuteInEditMode]
public class SSAOHelper : MonoBehaviour
{
    [SerializeField] private bool cook = false;
    [SerializeField] private string path = "Assets/PostFX/ssaoLUT.png";

    void Update()
    {
        if (!cook)
            return;
        cook = false;

        // to texture
        Texture2D tex = new Texture2D(16, 1, TextureFormat.ARGB32, false, false);

        List<int> shuffledIds = new List<int>();
        for (int i = 0; i < 16; ++i)
            shuffledIds.Add(i);
        shuffledIds.Shuffle();

        for (int i = 0; i < 16; ++i)
        {
            float angle = (shuffledIds[i] / 16.0f) * Mathf.PI;
            angle += Random.Range(-0.05f, 0.05f);
            float c = Mathf.Cos(angle);
            float s = Mathf.Sin(angle);
            tex.SetPixel(i, 0, new Color(c * 0.5f + 0.5f, 0.5f - s * 0.5f, s * 0.5f + 0.5f, c * 0.5f + 0.5f));
        }

        // (re-)save texture
        if (File.Exists(path))
            File.Delete(path);
        File.WriteAllBytes(path, tex.EncodeToPNG());
    }
}
#endif