using System;

namespace ComicSpidey
{
    // Height checks for an experimental rooftop mantle. Physics clearance and
    // collision-safe motion are separately handled by the Unity controller.
    public static class MantleMath
    {
        public const float MaximumRise = 2.1f;
        public const float FootClearance = 0.12f;
        public static bool TryLift(float feetY, float roofY, out float lift)
        {
            lift = 0;
            if (float.IsNaN(feetY) || float.IsInfinity(feetY) || float.IsNaN(roofY) || float.IsInfinity(roofY)) return false;
            float rise = roofY - feetY;
            if (rise < -0.05f || rise > MaximumRise) return false;
            lift = Math.Max(0, rise + FootClearance);
            return true;
        }
    }
}
