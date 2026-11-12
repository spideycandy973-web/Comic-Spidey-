using System;

namespace ComicSpidey
{
    // Small engine-independent part of the experimental tether. Removing only
    // outward radial speed keeps tangential and inward momentum intact.
    public static class SwingMath
    {
        // Preserve existing upward momentum while giving a bounded release boost.
        public static float ReleaseVerticalSpeed(float verticalSpeed)
        {
            const float boost = 3.2f, cap = 12f;
            return Math.Max(verticalSpeed, Math.Min(Math.Max(verticalSpeed, 0f) + boost, cap));
        }

        public static void LimitOutwardVelocity(float rx, float ry, float rz,
            float vx, float vy, float vz, out float resultX, out float resultY, out float resultZ)
        {
            float radiusSquared = rx * rx + ry * ry + rz * rz;
            float radialDot = rx * vx + ry * vy + rz * vz;
            if (radiusSquared > 0.000001f && radialDot > 0f)
            {
                float scale = radialDot / radiusSquared;
                vx -= rx * scale;
                vy -= ry * scale;
                vz -= rz * scale;
            }
            resultX = vx;
            resultY = vy;
            resultZ = vz;
        }
    }
}
