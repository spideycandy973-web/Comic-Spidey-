using System;

namespace ComicSpidey
{
    // A deliberately isolated test encounter, not the story's final boss fight.
    public enum OctopusState { Waiting, Telegraph, Recovery, Defeated }

    public sealed class OctopusFightRules
    {
        public const int MaximumHealth = 12;
        public int Health { get; private set; }
        public OctopusState State { get; private set; }
        public int Phase => Math.Min(4, 1 + (MaximumHealth - Health) / 3);
        private double until;

        public OctopusFightRules() { Reset(0); }
        public void Reset(double now) { Health = MaximumHealth; State = OctopusState.Waiting; until = now + 1.0; }

        // Return true once, exactly when a telegraphed slam lands.
        public bool Tick(double now, bool playerInRange)
        {
            if (State == OctopusState.Defeated || now < until) return false;
            if (State == OctopusState.Waiting && playerInRange)
            {
                State = OctopusState.Telegraph;
                until = now + Math.Max(0.6, 1.3 - Phase * 0.15);
                return false;
            }
            if (State == OctopusState.Telegraph)
            {
                State = OctopusState.Recovery;
                until = now + 1.5;
                return true;
            }
            if (State == OctopusState.Recovery)
            {
                State = OctopusState.Waiting;
                until = now + 0.8;
            }
            return false;
        }

        public bool TryHit()
        {
            if (State != OctopusState.Recovery || Health <= 0) return false;
            Health--;
            if (Health == 0) State = OctopusState.Defeated;
            return true;
        }
    }
}
