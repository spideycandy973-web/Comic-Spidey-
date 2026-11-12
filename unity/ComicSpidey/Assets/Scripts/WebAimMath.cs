using System;

namespace ComicSpidey
{
    // Scores candidates only; the Unity caller must separately test line of sight.
    public static class WebAimMath
    {
        public const float Range = 14f;
        public static bool TryScore(float forwardX, float forwardZ, float x, float y, float z, out float score)
        {
            score = 0;
            if (!Finite(forwardX) || !Finite(forwardZ) || !Finite(x) || !Finite(y) || !Finite(z)) return false;
            double f2 = (double)forwardX * forwardX + (double)forwardZ * forwardZ;
            double h2 = (double)x * x + (double)z * z;
            double d2 = h2 + (double)y * y;
            if (f2 < 0.0001 || h2 < 0.01 || d2 >= Range * Range) return false;
            double dot = ((double)forwardX * x + (double)forwardZ * z) / Math.Sqrt(f2 * h2);
            if (dot < 0.5) return false;
            dot = Math.Min(1, dot);
            score = (float)(Math.Sqrt(d2) + (1 - dot) * 8);
            return true;
        }
        private static bool Finite(float value) => !float.IsNaN(value) && !float.IsInfinity(value);
    }
}
