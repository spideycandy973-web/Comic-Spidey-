namespace ComicSpidey
{
    // Fair warning and cooldown for the placeholder melee enemy.
    public sealed class EnemyAttackTiming
    {
        private double nextAllowed, strikeAt;
        public bool WindingUp { get; private set; }

        // A strike is returned at most once and only if still in range.
        public bool Tick(double now, bool inRange)
        {
            if (WindingUp)
            {
                if (now < strikeAt) return false;
                WindingUp = false;
                nextAllowed = now + 1.5;
                return inRange;
            }
            if (inRange && now >= nextAllowed)
            {
                WindingUp = true;
                strikeAt = now + 0.6;
            }
            return false;
        }

        public void Interrupt(double earliestNextAttack)
        {
            WindingUp = false;
            if (earliestNextAttack > nextAllowed) nextAllowed = earliestNextAttack;
        }
    }
}
