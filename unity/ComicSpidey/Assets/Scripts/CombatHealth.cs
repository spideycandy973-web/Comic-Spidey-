using System;

namespace ComicSpidey
{
    // Engine-independent health for the early encounter prototype.
    public sealed class CombatHealth
    {
        public int Maximum { get; private set; }
        public int Current { get; private set; }
        public bool IsDefeated => Current == 0;

        public CombatHealth(int maximum)
        {
            if (maximum <= 0) throw new ArgumentOutOfRangeException(nameof(maximum));
            Maximum = maximum;
            Current = maximum;
        }

        // Returns true only when positive damage is applied to a living actor.
        public bool Damage(int amount)
        {
            if (amount <= 0 || IsDefeated) return false;
            Current = Math.Max(0, Current - amount);
            return true;
        }

        public void Restore() { Current = Maximum; }
    }
}
