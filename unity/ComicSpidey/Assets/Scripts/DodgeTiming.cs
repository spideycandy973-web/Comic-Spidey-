namespace ComicSpidey
{
    // Engine-independent timing for an early ground-dodge prototype.
    public sealed class DodgeTiming
    {
        private double activeUntil = -1;
        private double protectedUntil = -1;
        private double nextAllowed;

        public bool TryStart(double now, bool grounded, bool tethered)
        {
            if (!grounded || tethered || now < nextAllowed) return false;
            activeUntil = now + 0.32;
            protectedUntil = now + 0.22;
            nextAllowed = now + 0.85;
            return true;
        }

        public bool IsActive(double now) { return now < activeUntil; }
        public bool IsProtected(double now) { return now < protectedUntil; }
        // Interrupting a dodge doesn't reset its cooldown.
        public void Cancel() { activeUntil = protectedUntil = -1; }
        public void Reset() { Cancel(); nextAllowed = 0; }
    }
}
