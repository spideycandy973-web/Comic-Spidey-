using System;
using ComicSpidey;

static class Program
{
    static void Check(bool condition, string message)
    {
        if (!condition) throw new Exception(message);
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
        Console.WriteLine("Story logic tests passed.");
    }
}
