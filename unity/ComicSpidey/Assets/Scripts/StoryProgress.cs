using System;
using System.Collections.Generic;

namespace ComicSpidey
{
    // Engine-independent mission rules. Unity actors must call the appropriate
    // method for each event; this class does not create enemies, saves or UI.
    public enum ObjectiveKind { Travel, Fight, Boss, Interact, Escort, Complete }

    public sealed class StoryObjective
    {
        public readonly ObjectiveKind Kind;
        public readonly string Title;
        public readonly float X, Z, DestinationX, DestinationZ;
        public readonly int EnemyCount;
        public readonly string Interaction;

        public StoryObjective(ObjectiveKind kind, string title, float x, float z,
            int enemyCount = 0, string interaction = null, float destinationX = 0, float destinationZ = 0)
        {
            Kind = kind; Title = title; X = x; Z = z; EnemyCount = enemyCount;
            Interaction = interaction; DestinationX = destinationX; DestinationZ = destinationZ;
        }
    }

    public sealed class StoryProgress
    {
        private static readonly StoryObjective[] Objectives = {
            new StoryObjective(ObjectiveKind.Travel, "Investigate the disturbance", 0, -44),
            new StoryObjective(ObjectiveKind.Fight, "Stop the attackers", 0, -44, 2),
            new StoryObjective(ObjectiveKind.Travel, "Reach the north crossing", 0, -132),
            new StoryObjective(ObjectiveKind.Boss, "Stop Doctor Octopus", 0, -132, 1),
            new StoryObjective(ObjectiveKind.Travel, "Find the power relay", 88, -132),
            new StoryObjective(ObjectiveKind.Interact, "Disable the power relay", 88, -132, interaction: "relay"),
            new StoryObjective(ObjectiveKind.Travel, "Find the stranded civilian", 176, -132),
            new StoryObjective(ObjectiveKind.Escort, "Escort the civilian to safety", 176, -132, destinationX: 176, destinationZ: -44),
            new StoryObjective(ObjectiveKind.Travel, "Follow the getaway crew", 264, -44),
            new StoryObjective(ObjectiveKind.Fight, "Stop the getaway crew", 264, -44, 3),
            new StoryObjective(ObjectiveKind.Travel, "Reach the generator", 264, -132),
            new StoryObjective(ObjectiveKind.Boss, "Confront Doctor Octopus", 264, -132, 1),
            new StoryObjective(ObjectiveKind.Interact, "Stabilize the generator", 264, -132, interaction: "generator"),
            new StoryObjective(ObjectiveKind.Complete, "City secured", 264, -132)
        };
        private readonly HashSet<string> defeated = new HashSet<string>();
        public int Stage { get; private set; }
        public StoryObjective Current => Objectives[Stage];
        public int DefeatedCount => defeated.Count;
        public bool IsComplete => Current.Kind == ObjectiveKind.Complete;

        private void Advance() { Stage++; defeated.Clear(); }
        private static bool Near(float x, float y, float z, float targetX, float targetZ, float radius)
        {
            float dx = x - targetX, dz = z - targetZ;
            return Math.Abs(y) < 3f && dx * dx + dz * dz < radius * radius;
        }

        public bool Visit(float x, float y, float z)
        {
            if (Current.Kind != ObjectiveKind.Travel || !Near(x, y, z, Current.X, Current.Z, 8f)) return false;
            Advance(); return true;
        }

        // Only a registered enemy ID for the active encounter may be reported.
        // The caller owns encounter membership and must validate it before calling.
        public bool EnemyDefeated(string enemyId)
        {
            if ((Current.Kind != ObjectiveKind.Fight && Current.Kind != ObjectiveKind.Boss) ||
                string.IsNullOrWhiteSpace(enemyId) || !defeated.Add(enemyId)) return false;
            if (defeated.Count >= Current.EnemyCount) Advance();
            return true;
        }

        public bool Interact(string target, float x, float y, float z)
        {
            if (Current.Kind != ObjectiveKind.Interact || target != Current.Interaction ||
                !Near(x, y, z, Current.X, Current.Z, 4f)) return false;
            Advance(); return true;
        }

        public bool FinishEscort(float playerX, float playerY, float playerZ, float civilianX, float civilianY, float civilianZ)
        {
            if (Current.Kind != ObjectiveKind.Escort ||
                !Near(playerX, playerY, playerZ, Current.DestinationX, Current.DestinationZ, 8f) ||
                !Near(civilianX, civilianY, civilianZ, Current.DestinationX, Current.DestinationZ, 8f)) return false;
            Advance(); return true;
        }
    }
}
