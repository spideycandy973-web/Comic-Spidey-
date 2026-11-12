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
        var options = new GraphicsOptionsData(-5, 100, -2, true);
        Check(options.Quality == 0 && options.FrameRateIndex == 2 && options.ResolutionIndex == 0, "Corrupt preference indices are clamped");
        Check(GraphicsOptionsData.FrameRates[options.FrameRateIndex] == 120, "120 is an available target");
        options.CycleFrameRate();
        options.CycleResolution();
        options.CycleQuality();
        options.ToggleShadows();
        Check(GraphicsOptionsData.FrameRates[options.FrameRateIndex] == 30 &&
            GraphicsOptionsData.ResolutionPercent[options.ResolutionIndex] == 75 &&
            options.Quality == 1 && !options.Shadows, "Options cycle and toggle");
        var checkpoint = new PrototypeCheckpoint();
        Check(checkpoint.Encode() == "v1:0:0", "New test checkpoint starts in travel");
        Check(!checkpoint.MarkDefeated(0), "Defeat cannot happen before encounter");
        checkpoint.StartEncounter();
        Check(!checkpoint.MarkDefeated(-1) && !checkpoint.MarkDefeated(2), "Invalid enemy IDs are rejected");
        Check(checkpoint.MarkDefeated(1) && !checkpoint.MarkDefeated(1), "Defeat is recorded once");
        Check(PrototypeCheckpoint.TryDecode(checkpoint.Encode(), out var partial) &&
            partial.Phase == 1 && partial.IsDefeated(1) && !partial.IsDefeated(0), "Partial checkpoint round trip");
        Check(partial.MarkDefeated(0) && partial.Phase == 2 && partial.Encode() == "v1:2:3", "Completion persists");
        Check(PrototypeCheckpoint.TryDecode(partial.Encode(), out var complete) && complete.Phase == 2 &&
            !complete.MarkDefeated(0), "Completed checkpoint round trip is terminal");
        foreach (string invalid in new[] { "", "v2:0:0", "v1:0:1", "v1:1:3", "v1:2:0", "v1:-1:0", "v1:1:0:extra", "v1:a:0" })
            Check(!PrototypeCheckpoint.TryDecode(invalid, out _), "Reject malformed checkpoint: " + invalid);
        var dodge = new DodgeTiming();
        Check(!dodge.IsActive(0) && !dodge.IsProtected(0), "Dodge starts inactive");
        Check(!dodge.TryStart(1, false, false) && !dodge.TryStart(1, true, true), "Dodge requires ground and no tether");
        Check(dodge.TryStart(1, true, false) && dodge.IsActive(1.1) && dodge.IsProtected(1.1), "Dodge starts with protection");
        Check(!dodge.IsProtected(1.23) && dodge.IsActive(1.23), "Protection ends before the dodge");
        Check(!dodge.IsActive(1.33) && !dodge.TryStart(1.5, true, false), "Cooldown continues after the dodge");
        Check(dodge.TryStart(1.9, true, false), "Can dodge after cooldown");
        dodge.Cancel();
        Check(!dodge.IsActive(1.91) && !dodge.IsProtected(1.91) && !dodge.TryStart(2, true, false), "Cancel retains cooldown");
        dodge.Reset();
        Check(dodge.TryStart(2, true, false), "Reset clears cooldown");
        Console.WriteLine("Story, swing, health, graphics, checkpoint and dodge timing tests passed.");
    }
}
