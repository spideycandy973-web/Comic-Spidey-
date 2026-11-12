namespace ComicSpidey
{
    public enum CrimeStage { Waiting, Alert, Active, Resolved }
    public enum CrimeEvent { None, AlertStarted, Expired }

    // Engine-independent rules for the free-roam test crime, not campaign saves.
    public sealed class CrimeCycle
    {
        public CrimeStage Stage { get; private set; }
        public int DefeatedCount { get; private set; }
        public int ResolvedCount { get; private set; }
        private int defeatedMask;
        private double until;

        public CrimeCycle(double now) { Stage = CrimeStage.Waiting; until = now + 10; }

        public CrimeEvent Tick(double now)
        {
            if (now < until) return CrimeEvent.None;
            if (Stage == CrimeStage.Waiting)
            {
                Stage = CrimeStage.Alert;
                until = now + 90;
                return CrimeEvent.AlertStarted;
            }
            if (Stage == CrimeStage.Alert || Stage == CrimeStage.Active)
            {
                ResetWaiting(now);
                return CrimeEvent.Expired;
            }
            if (Stage == CrimeStage.Resolved) ResetWaiting(now);
            return CrimeEvent.None;
        }

        public bool StartEncounter(double now)
        {
            if (Stage != CrimeStage.Alert || now >= until) return false;
            Stage = CrimeStage.Active;
            defeatedMask = DefeatedCount = 0;
            until = now + 120;
            return true;
        }

        public bool Defeat(int index, double now)
        {
            if (Stage != CrimeStage.Active || now >= until || index < 0 || index >= 2) return false;
            int bit = 1 << index;
            if ((defeatedMask & bit) != 0) return false;
            defeatedMask |= bit;
            DefeatedCount++;
            if (DefeatedCount == 2)
            {
                Stage = CrimeStage.Resolved;
                ResolvedCount++;
                until = now + 6;
            }
            return true;
        }

        public void Fail(double now)
        {
            if (Stage == CrimeStage.Alert || Stage == CrimeStage.Active) ResetWaiting(now);
        }

        private void ResetWaiting(double now)
        {
            Stage = CrimeStage.Waiting;
            defeatedMask = DefeatedCount = 0;
            until = now + 30;
        }
    }
}
