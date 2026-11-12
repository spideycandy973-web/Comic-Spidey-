using System;

namespace ComicSpidey
{
    // Portable clock logic; phase 0 = midnight, .25 = sunrise, .5 = noon.
    public sealed class DayNightClock
    {
        public const double DayDurationSeconds = 720;
        public double Phase { get; private set; }

        public DayNightClock(double initialPhase)
        {
            Phase = IsFinite(initialPhase) ? Wrap(initialPhase) : 0.42;
        }

        public void Advance(double seconds)
        {
            if (!IsFinite(seconds) || seconds <= 0) return;
            // Reduce before addition, keeping the result finite for long sleeps.
            Phase = Wrap(Phase + (seconds % DayDurationSeconds) / DayDurationSeconds);
        }

        private static double Wrap(double value) { return value - Math.Floor(value); }
        private static bool IsFinite(double value) { return !double.IsNaN(value) && !double.IsInfinity(value); }
    }
}
