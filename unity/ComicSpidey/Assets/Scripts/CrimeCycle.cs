namespace ComicSpidey
{
    public enum CrimeStage { Waiting, Alert, Active, AwaitingRescue, Resolved }
    public enum CrimeEvent { None, AlertStarted, Expired }

    // Engine-independent rules for the free-roam test crime, not campaign saves.
    public sealed class CrimeCycle
    {
        public CrimeStage Stage { get; private set; }
        public int DefeatedCount { get; private set; }
        public int ResolvedCount { get; private set; }
        private int defeatedMask;
        private bool needsRescue;
        private double until;

        public CrimeCycle(double now, int resolvedCount = 0)
        {
            if (!ValidTime(now)) throw new System.ArgumentOutOfRangeException(nameof(now));
            if (resolvedCount < 0 || resolvedCount > CrimeProgressSave.MaxCompleted)
                throw new System.ArgumentOutOfRangeException(nameof(resolvedCount));
            ResolvedCount = resolvedCount;
            Stage = CrimeStage.Waiting;
            until = now + 10;
        }

        private static bool ValidTime(double now) => !double.IsNaN(now) && !double.IsInfinity(now);

        // Countdown is informational; Tick remains the sole transition owner.
        public int RemainingSeconds(double now)
        {
            if (Stage != CrimeStage.Alert && Stage != CrimeStage.Active && Stage != CrimeStage.AwaitingRescue) return 0;
            if (!ValidTime(now)) return 0;
            return (int)System.Math.Ceiling(System.Math.Max(0, System.Math.Min(120, until - now)));
        }

        public CrimeEvent Tick(double now)
        {
            if (!ValidTime(now) || now < until) return CrimeEvent.None;
            if (Stage == CrimeStage.Waiting)
            {
                Stage = CrimeStage.Alert;
                until = now + 90;
                return CrimeEvent.AlertStarted;
            }
            if (Stage == CrimeStage.Alert || Stage == CrimeStage.Active || Stage == CrimeStage.AwaitingRescue)
            {
                ResetWaiting(now);
                return CrimeEvent.Expired;
            }
            if (Stage == CrimeStage.Resolved) ResetWaiting(now);
            return CrimeEvent.None;
        }

        public bool StartEncounter(double now, bool rescue = false)
        {
            if (!ValidTime(now) || Stage != CrimeStage.Alert || now >= until) return false;
            Stage = CrimeStage.Active;
            needsRescue = rescue;
            defeatedMask = DefeatedCount = 0;
            until = now + 120;
            return true;
        }

        public bool Defeat(int index, double now)
        {
            if (!ValidTime(now) || Stage != CrimeStage.Active || now >= until || index < 0 || index >= 2) return false;
            int bit = 1 << index;
            if ((defeatedMask & bit) != 0) return false;
            defeatedMask |= bit;
            DefeatedCount++;
            if (DefeatedCount == 2)
            {
                if (needsRescue)
                {
                    Stage = CrimeStage.AwaitingRescue;
                    until = now + 45;
                }
                else Resolve(now);
            }
            return true;
        }

        // Unity caller verifies civilian proximity and unobstructed interaction.
        public bool Rescue(double now)
        {
            if (!ValidTime(now) || Stage != CrimeStage.AwaitingRescue || now >= until) return false;
            Resolve(now);
            return true;
        }

        private void Resolve(double now)
        {
            Stage = CrimeStage.Resolved;
            if (ResolvedCount < CrimeProgressSave.MaxCompleted) ResolvedCount++;
            until = now + 6;
        }

        // Reset only the total; do not interrupt an active encounter.
        public void ClearTotal() { ResolvedCount = 0; }

        public void Fail(double now)
        {
            if (ValidTime(now) && (Stage == CrimeStage.Alert || Stage == CrimeStage.Active || Stage == CrimeStage.AwaitingRescue)) ResetWaiting(now);
        }

        private void ResetWaiting(double now)
        {
            Stage = CrimeStage.Waiting;
            defeatedMask = DefeatedCount = 0;
            needsRescue = false;
            until = now + 30;
        }
    }
}
