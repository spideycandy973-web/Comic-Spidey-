using System;

namespace ComicSpidey
{
    // Session-only prototype web ammunition. No campaign progression or save.
    public sealed class WebShooter
    {
        public const int Capacity = 3;
        public const double RechargeSeconds = 4;
        public const double ShotCooldown = 0.45;
        public const double StunSeconds = 2.0;
        public int Charges { get; private set; } = Capacity;
        private double rechargeProgress;
        private double nextShot;

        // A shot is spent even if it misses; cooldown and ammunition are both required.
        public bool TryFire(double now)
        {
            if (double.IsNaN(now) || double.IsInfinity(now) || now < nextShot || Charges == 0) return false;
            Charges--;
            nextShot = now + ShotCooldown;
            return true;
        }

        // Call once per unpaused frame. Progress while full is discarded so a
        // player cannot bank a free instantaneous refill before firing.
        public void Advance(double seconds)
        {
            if (double.IsNaN(seconds) || double.IsInfinity(seconds) || seconds <= 0) return;
            if (Charges == Capacity) { rechargeProgress = 0; return; }
            rechargeProgress += seconds;
            while (rechargeProgress >= RechargeSeconds && Charges < Capacity)
            {
                rechargeProgress -= RechargeSeconds;
                Charges++;
            }
            if (Charges == Capacity) rechargeProgress = 0;
        }

        public void Reset() { Charges = Capacity; rechargeProgress = 0; nextShot = 0; }
    }
}
