using System;
using ComicSpidey;

static class Program
{
    static void Check(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
    }

    static void CheckSwing(float rx, float ry, float rz, float vx, float vy, float vz,
        float expectedX, float expectedY, float expectedZ, string message)
    {
        SwingMath.LimitOutwardVelocity(rx, ry, rz, vx, vy, vz, out float x, out float y, out float z);
        Check(Math.Abs(x - expectedX) < 0.0001f && Math.Abs(y - expectedY) < 0.0001f &&
            Math.Abs(z - expectedZ) < 0.0001f, message);
    }

    static void Main()
    {
        var story = new StoryProgress();
        Check(story.Stage == 0 && story.Current.Kind == ObjectiveKind.Travel, "Initial objective");
        Check(!story.Visit(0, 9, -44) && !story.Visit(8, 0, -44), "Travel requires ground height and proximity");
        Check(!story.EnemyDefeated("one"), "Combat cannot advance travel");
        Check(story.Visit(0, 0, -44) && story.Stage == 1, "First destination");
        Check(!story.EnemyDefeated("") && story.EnemyDefeated("one"), "Count first distinct attacker");
        Check(!story.EnemyDefeated("one") && story.Stage == 1, "Duplicate defeat does not advance");
        Check(story.EnemyDefeated("two") && story.Stage == 2 && story.DefeatedCount == 0, "Two attackers completed");
        Check(story.Visit(0, 0, -132), "North crossing");
        Check(story.EnemyDefeated("ock1"), "First boss");
        Check(story.Visit(88, 0, -132), "Find relay");
        Check(!story.Interact("generator", 88, 0, -132), "Wrong object cannot advance");
        Check(!story.Interact("relay", 95, 0, -132), "Remote interaction rejected");
        Check(story.Interact("relay", 88, 0, -132), "Relay interaction");
        Check(story.Visit(176, 0, -132), "Find civilian");
        Check(!story.FinishEscort(176, 0, -44, 176, 0, -132), "Civilian must reach safety too");
        Check(story.FinishEscort(176, 0, -44, 176, 0, -44), "Escort completed");
        Check(story.Visit(264, 0, -44), "Find crew");
        Check(story.EnemyDefeated("a") && story.EnemyDefeated("b") && story.EnemyDefeated("c"), "Stop crew");
        Check(story.Visit(264, 0, -132), "Find generator");
        Check(story.EnemyDefeated("ock2"), "Second boss");
        Check(story.Interact("generator", 264, 0, -132), "Stabilize generator");
        Check(story.IsComplete && !story.Visit(264, 0, -132) && !story.EnemyDefeated("extra"), "Completion is terminal");
        CheckSwing(0, -5, 0, 3, -4, 2, 3, 0, 2, "Outward velocity is removed");
        CheckSwing(0, -5, 0, 3, 4, 2, 3, 4, 2, "Inward velocity is retained");
        CheckSwing(0, -5, 0, 3, 0, 2, 3, 0, 2, "Tangential velocity is retained");
        CheckSwing(0, 0, 0, 3, -4, 2, 3, -4, 2, "Zero-length rope is safe");
        CheckSwing(1, 1, 0, 2, 0, 1, 1, -1, 1, "Diagonal projection");
        bool rejectedInvalidMaximum = false;
        try { new CombatHealth(0); }
        catch (ArgumentOutOfRangeException) { rejectedInvalidMaximum = true; }
        Check(rejectedInvalidMaximum, "Non-positive maximum health is rejected");
        var health = new CombatHealth(3);
        Check(!health.Damage(0) && !health.Damage(-1) && health.Current == 3, "Invalid damage is ignored");
        Check(health.Damage(1) && health.Current == 2 && !health.IsDefeated, "Damage reduces health");
        Check(health.Damage(99) && health.Current == 0 && health.IsDefeated, "Damage is clamped at zero");
        Check(!health.Damage(1), "Defeated actor cannot take damage twice");
        health.Restore();
        Check(health.Current == 3 && !health.IsDefeated, "Restore returns actor to maximum health");
        Console.WriteLine("Story, swing math and combat health tests passed.");
    }
}
