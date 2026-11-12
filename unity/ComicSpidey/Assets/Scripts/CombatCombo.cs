namespace ComicSpidey
{
    // Timing and damage rules for the prototype encounter; no animation/AI.
    public sealed class CombatCombo
    {
        public const double HeavyHoldSeconds = 0.55;
        private const double ChainWindow = 1.25;
        private double nextAttack;
        private double lastHit = -100;
        private int chain;
        public int Chain => chain;

        // An attack consumes a cooldown even when it misses or is blocked.
        // Only successful light attacks count toward the three-hit chain.
        public bool TryAttack(double now, bool heavy, bool connected, out int damage, out double stunSeconds)
        {
            damage = 0;
            stunSeconds = 0;
            if (now < nextAttack) return false;
            nextAttack = now + (heavy ? 0.75 : 0.32);
            if (!connected) { CancelChain(); return true; }
            if (heavy)
            {
                CancelChain();
                damage = 2;
                stunSeconds = 1.1;
                return true;
            }
            if (now - lastHit > ChainWindow) chain = 0;
            chain++;
            lastHit = now;
            if (chain == 3)
            {
                damage = 2;
                stunSeconds = 0.6;
                CancelChain();
            }
            else damage = 1;
            return true;
        }

        public void CancelChain() { chain = 0; lastHit = -100; }
        public void Reset() { CancelChain(); nextAttack = 0; }
    }
}
