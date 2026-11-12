using System;

namespace ComicSpidey
{
    // Relative directions in the horizontal plane; Unity-independent for tests.
    public static class CompassMath
    {
        public static string Direction(double forwardX, double forwardZ, double x, double y, double z)
        {
            if (x * x + z * z < 0.25) return y > 0 ? "above" : "below";
            if (forwardX * forwardX + forwardZ * forwardZ < 0.000001) { forwardX = 0; forwardZ = 1; }
            double dot = forwardX * x + forwardZ * z;
            double cross = forwardZ * x - forwardX * z;
            double angle = Math.Atan2(cross, dot) * 180 / Math.PI;
            return Math.Abs(angle) > 135 ? "behind" : Math.Abs(angle) < 35 ? "ahead" : angle > 0 ? "right" : "left";
        }
    }
}
