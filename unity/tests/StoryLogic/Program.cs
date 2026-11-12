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
        var fight = new OctopusFightRules();
        Check(fight.Health == 12 && fight.Phase == 1 && fight.State == OctopusState.Waiting, "Boss starts at full health");
        Check(!fight.TryHit() && !fight.Tick(1, false), "Boss ignores hits outside recovery and waits for player");
        double now = 2;
        for (int phase = 1; phase <= 4; phase++)
        {
            Check(fight.Phase == phase && !fight.Tick(now, true) && fight.State == OctopusState.Telegraph, "Boss telegraphs phase " + phase);
            Check(!fight.TryHit(), "Boss cannot be hit during telegraph");
            now += 2;
            Check(fight.Tick(now, false) && !fight.Tick(now, true) && fight.State == OctopusState.Recovery, "Slam occurs once and enters recovery");
            Check(fight.TryHit() && fight.TryHit() && fight.TryHit(), "Three hits during recovery");
            if (phase < 4)
            {
                now += 2;
                Check(!fight.Tick(now, true) && fight.State == OctopusState.Waiting, "Recovery expires");
                now += 1;
            }
        }
        Check(fight.Health == 0 && fight.Phase == 4 && fight.State == OctopusState.Defeated && !fight.TryHit() && !fight.Tick(100, true), "Boss defeat is terminal");
        fight.Reset(100);
        Check(fight.Health == 12 && fight.Phase == 1 && fight.State == OctopusState.Waiting && !fight.Tick(100, true), "Boss retry resets health and delay");
        var combo = new CombatCombo();
        Check(combo.TryAttack(1, false, true, out int damage, out double stun) && damage == 1 && stun == 0 && combo.Chain == 1, "First light hit begins a chain");
        Check(!combo.TryAttack(1.1, false, true, out damage, out stun) && combo.Chain == 1, "Cooldown rejects fast input without changing chain");
        Check(combo.TryAttack(1.4, false, true, out damage, out stun) && damage == 1 && combo.Chain == 2, "Second light hit");
        Check(combo.TryAttack(1.8, false, true, out damage, out stun) && damage == 2 && stun == 0.6 && combo.Chain == 0, "Third light hit is a stun finisher");
        Check(combo.TryAttack(2.2, false, true, out damage, out stun) && combo.Chain == 1, "Next chain starts after finisher");
        Check(combo.TryAttack(2.6, false, false, out damage, out stun) && damage == 0 && combo.Chain == 0, "Miss resets chain and consumes cooldown");
        Check(!combo.TryAttack(2.7, true, true, out damage, out stun), "Miss cooldown blocks immediate follow-up");
        Check(combo.TryAttack(3.0, true, true, out damage, out stun) && damage == 2 && stun == 1.1 && combo.Chain == 0, "Heavy attack damages and stuns");
        Check(!combo.TryAttack(3.5, false, true, out damage, out stun), "Heavy attack has longer cooldown");
        Check(combo.TryAttack(3.8, false, true, out damage, out stun) && combo.Chain == 1, "Light hit after heavy");
        Check(combo.TryAttack(5.2, false, true, out damage, out stun) && combo.Chain == 1, "Expired chain restarts");
        combo.CancelChain();
        Check(combo.Chain == 0 && !combo.TryAttack(5.3, false, true, out damage, out stun), "Cancel chain preserves cooldown");
        combo.Reset();
        Check(combo.TryAttack(5.3, false, true, out damage, out stun), "Reset clears cooldown");
        var heavyBoss = new OctopusFightRules();
        heavyBoss.Tick(1, true);
        heavyBoss.Tick(3, true);
        Check(!heavyBoss.TryHit(0) && heavyBoss.Health == 12, "Boss rejects zero damage");
        Check(heavyBoss.TryHit(2) && heavyBoss.Health == 10, "Boss takes heavy damage in recovery");
        Check(heavyBoss.TryHit(50) && heavyBoss.Health == 0 && heavyBoss.State == OctopusState.Defeated, "Boss damage clamps to zero");
        var crime = new CrimeCycle(0);
        Check(crime.Stage == CrimeStage.Waiting && !crime.StartEncounter(1) && crime.Tick(9) == CrimeEvent.None, "Crime waits before alert");
        Check(crime.Tick(10) == CrimeEvent.AlertStarted && crime.Stage == CrimeStage.Alert, "Crime alert appears");
        Check(crime.StartEncounter(11) && !crime.StartEncounter(11), "Alert starts a single encounter");
        Check(!crime.Defeat(-1, 12) && !crime.Defeat(2, 12), "Reject unregistered attackers");
        Check(crime.Defeat(0, 12) && !crime.Defeat(0, 12) && crime.DefeatedCount == 1, "Count each attacker once");
        Check(crime.Defeat(1, 13) && crime.Stage == CrimeStage.Resolved && crime.ResolvedCount == 1, "Crime resolves after both attackers");
        Check(!crime.Defeat(1, 13) && crime.Tick(18) == CrimeEvent.None && crime.Stage == CrimeStage.Resolved, "Resolution is shown briefly");
        Check(crime.Tick(19) == CrimeEvent.None && crime.Stage == CrimeStage.Waiting && crime.Tick(48) == CrimeEvent.None, "Completed encounter enters cooldown");
        Check(crime.Tick(49) == CrimeEvent.AlertStarted && crime.Tick(139) == CrimeEvent.Expired && crime.Stage == CrimeStage.Waiting, "Ignored alert expires");
        Check(crime.Tick(169) == CrimeEvent.AlertStarted && crime.StartEncounter(170), "New crime can start after expiry");
        Check(crime.Tick(290) == CrimeEvent.Expired && crime.Stage == CrimeStage.Waiting, "Active crime expires");
        Check(crime.Tick(320) == CrimeEvent.AlertStarted && crime.StartEncounter(321), "Crime restarts after failure");
        crime.Fail(322);
        Check(crime.Stage == CrimeStage.Waiting && crime.ResolvedCount == 1 && crime.Tick(351) == CrimeEvent.None && crime.Tick(352) == CrimeEvent.AlertStarted, "Player defeat cancels crime and keeps session count");
        Check(CrimeProgressSave.TryDecode(CrimeProgressSave.Encode(27), out int crimeTotal) && crimeTotal == 27, "Crime total round trip");
        foreach (string invalid in new[] { "", "v2:1", "v1:-1", "v1:+1", "v1: 1", "v1:1:2", "v1:1000001", "v1:2147483648" })
            Check(!CrimeProgressSave.TryDecode(invalid, out _), "Reject invalid crime save: " + invalid);
        bool rejectedCrimeTotal = false;
        try { CrimeProgressSave.Encode(-1); } catch (ArgumentOutOfRangeException) { rejectedCrimeTotal = true; }
        Check(rejectedCrimeTotal, "Reject negative crime total");
        var restoredCrime = new CrimeCycle(0, 27);
        Check(restoredCrime.ResolvedCount == 27 && restoredCrime.Stage == CrimeStage.Waiting, "Restores only completed count, not active crime");
        restoredCrime.Tick(10); restoredCrime.StartEncounter(11); restoredCrime.Defeat(0, 12);
        restoredCrime.ClearTotal();
        Check(restoredCrime.Stage == CrimeStage.Active && restoredCrime.DefeatedCount == 1 && restoredCrime.ResolvedCount == 0, "Resetting crime count does not interrupt an active crime");
        restoredCrime.Defeat(1, 13);
        Check(restoredCrime.ResolvedCount == 1, "New crime increments after reset");
        var saturatedCrime = new CrimeCycle(0, CrimeProgressSave.MaxCompleted);
        saturatedCrime.Tick(10); saturatedCrime.StartEncounter(11); saturatedCrime.Defeat(0, 12); saturatedCrime.Defeat(1, 13);
        Check(saturatedCrime.ResolvedCount == CrimeProgressSave.MaxCompleted, "Crime total does not overflow");
        var rotation = new CrimeRotation(true);
        Check(rotation.NextIsRescue() && !rotation.NextIsRescue() && rotation.NextIsRescue(), "Alerts alternate after a rescue-first start");
        var otherRotation = new CrimeRotation(false);
        Check(!otherRotation.NextIsRescue() && otherRotation.NextIsRescue(), "Alerts alternate after a combat-first start");
        var rescue = new CrimeCycle(0, 4);
        Check(!rescue.Rescue(1) && rescue.ResolvedCount == 4, "Cannot rescue before alert");
        rescue.Tick(10);
        Check(!rescue.StartEncounter(double.NaN, true) && rescue.StartEncounter(11, true), "Rescue encounter starts once");
        Check(!rescue.Rescue(12) && rescue.Defeat(0, 12) && !rescue.Rescue(12), "Cannot rescue before both attackers are defeated");
        Check(rescue.Defeat(1, 13) && rescue.Stage == CrimeStage.AwaitingRescue && rescue.ResolvedCount == 4, "Rescue requires an extra interaction before credit");
        Check(rescue.RemainingSeconds(13) == 45 && !rescue.Defeat(1, 14) && !rescue.Rescue(double.NaN), "Awaiting rescue has countdown and rejects invalid events");
        rescue.ClearTotal();
        Check(rescue.Stage == CrimeStage.AwaitingRescue && rescue.ResolvedCount == 0, "Reset count preserves a pending rescue");
        Check(rescue.Rescue(14) && rescue.Stage == CrimeStage.Resolved && rescue.ResolvedCount == 1 && !rescue.Rescue(14), "Rescue completes and credits exactly once");
        Check(rescue.Tick(20) == CrimeEvent.None && rescue.Stage == CrimeStage.Waiting, "Completed rescue returns to waiting");
        rescue.Tick(50); rescue.StartEncounter(51, true); rescue.Defeat(0, 52); rescue.Defeat(1, 53);
        Check(!rescue.Rescue(98) && rescue.Tick(98) == CrimeEvent.Expired && rescue.ResolvedCount == 1, "Rescue expires without credit at deadline");
        rescue.Tick(128); rescue.StartEncounter(129, true); rescue.Defeat(0, 130); rescue.Defeat(1, 131);
        rescue.Fail(132);
        Check(rescue.Stage == CrimeStage.Waiting && rescue.ResolvedCount == 1 && !rescue.Rescue(132), "Failure during rescue cleans up without credit");
        rescue.Tick(162); rescue.StartEncounter(163); rescue.Defeat(0, 164); rescue.Defeat(1, 165);
        Check(rescue.Stage == CrimeStage.Resolved && rescue.ResolvedCount == 2, "Ordinary crime works after a rescue failure");
        var cappedRescue = new CrimeCycle(0, CrimeProgressSave.MaxCompleted);
        cappedRescue.Tick(10); cappedRescue.StartEncounter(11, true); cappedRescue.Defeat(0, 12); cappedRescue.Defeat(1, 13); cappedRescue.Rescue(14);
        Check(cappedRescue.ResolvedCount == CrimeProgressSave.MaxCompleted, "Rescue count does not overflow");
        var invalidTimeCrime = new CrimeCycle(0);
        Check(invalidTimeCrime.Tick(double.NaN) == CrimeEvent.None && invalidTimeCrime.Stage == CrimeStage.Waiting, "Invalid tick cannot start a crime");
        bool rejectedInvalidCrimeTime = false;
        try { new CrimeCycle(double.PositiveInfinity); } catch (ArgumentOutOfRangeException) { rejectedInvalidCrimeTime = true; }
        Check(rejectedInvalidCrimeTime, "Invalid crime clock is rejected");
        bool invalidTraffic = false;
        try { new TrafficRoute(3, 3, 3, 1, 4); } catch (ArgumentOutOfRangeException) { invalidTraffic = true; }
        Check(invalidTraffic, "Traffic rejects an empty route");
        invalidTraffic = false;
        try { new TrafficRoute(0, 10, 2, 0, 4); } catch (ArgumentOutOfRangeException) { invalidTraffic = true; }
        Check(invalidTraffic, "Traffic rejects invalid direction");
        var traffic = new TrafficRoute(-10, 10, 0, 1, 4);
        Check(traffic.Preview(1) == 4 && traffic.Position == 0, "Traffic preview does not move vehicle");
        Check(traffic.Advance(1, true) == 0 && traffic.Position == 0, "Traffic stops for a blocker");
        Check(traffic.Advance(1, false) == 4 && traffic.Position == 4, "Traffic advances once clear");
        Check(traffic.Advance(100, false) == 6 && traffic.Position == 10 && traffic.Direction == -1, "Traffic stops at route end and reverses");
        Check(traffic.Advance(1, true) == 0 && traffic.Direction == -1, "Traffic remains stopped at a blocked turn");
        Check(traffic.Advance(100, false) == -20 && traffic.Position == -10 && traffic.Direction == 1, "Traffic remains inside both boundaries");
        Check(traffic.Advance(double.NaN, false) == 0 && traffic.Advance(double.PositiveInfinity, false) == 0 && traffic.Advance(-1, false) == 0, "Traffic ignores invalid elapsed time");
        var endpointTraffic = new TrafficRoute(0, 5, 0, -1, 1);
        Check(endpointTraffic.Direction == 1 && endpointTraffic.Advance(1, false) == 1, "Traffic starts facing inward at route end");
        var clock = new DayNightClock(0.99);
        clock.Advance(14.4);
        Check(Math.Abs(clock.Phase - 0.01) < 0.000001, "Day clock wraps midnight");
        double phaseBefore = clock.Phase;
        clock.Advance(-2); clock.Advance(0); clock.Advance(double.NaN); clock.Advance(double.PositiveInfinity);
        Check(clock.Phase == phaseBefore, "Day clock ignores invalid or nonpositive elapsed time");
        clock.Advance(DayNightClock.DayDurationSeconds * 3);
        Check(Math.Abs(clock.Phase - phaseBefore) < 0.000001, "Complete days retain phase");
        Check(Math.Abs(new DayNightClock(-0.25).Phase - 0.75) < 0.000001, "Day clock normalizes negative phases");
        Check(Math.Abs(new DayNightClock(double.NaN).Phase - 0.42) < 0.000001, "Day clock handles invalid phase");
        var melee = new EnemyAttackTiming();
        Check(!melee.Tick(0, false) && !melee.WindingUp, "Enemy waits until player enters range");
        Check(!melee.Tick(1, true) && melee.WindingUp, "Enemy warns before attacking");
        Check(!melee.Tick(1.5, true) && melee.WindingUp, "Enemy wind-up lasts through warning");
        Check(melee.Tick(1.7, true) && !melee.WindingUp, "Enemy strikes after warning");
        Check(!melee.Tick(2, true) && !melee.WindingUp, "Enemy cooldown prevents repeated strikes");
        Check(!melee.Tick(3.3, true) && melee.WindingUp, "Enemy can attack again after cooldown");
        Check(!melee.Tick(4.0, false) && !melee.WindingUp, "Leaving range avoids the strike");
        Check(!melee.Tick(5.6, true) && melee.WindingUp, "Enemy starts another warning");
        melee.Interrupt(7.2);
        Check(!melee.WindingUp && !melee.Tick(7, true), "Hit stun interrupts and delays attack");
        Check(!melee.Tick(7.3, true) && melee.WindingUp, "Enemy recovers after interruption");
        var tokens = new CollectibleProgress();
        Check(tokens.Count == 0 && !tokens.Collect(-1) && !tokens.Collect(8), "Collectibles start empty and reject out-of-range IDs");
        Check(tokens.Collect(0) && tokens.Collect(7) && !tokens.Collect(7) && tokens.Count == 2, "Unique token collection");
        Check(CollectibleProgress.TryDecode(tokens.Encode(), out var restoredTokens) && restoredTokens.Contains(0) && restoredTokens.Contains(7) && restoredTokens.Count == 2, "Collectible save round trip");
        foreach (string invalid in new[] { "", "v2:1", "v1:-1", "v1:+1", "v1: 1", "v1:256", "v1:1:2", "v1:2147483648" })
            Check(!CollectibleProgress.TryDecode(invalid, out _), "Reject invalid token save: " + invalid);
        for (int mask = 0; mask < 256; mask++)
        {
            Check(CollectibleProgress.TryDecode("v1:" + mask, out var sample), "Decode valid token mask");
            int expectedCount = 0;
            for (int bit = 0; bit < CollectibleProgress.Total; bit++)
            {
                bool expected = (mask & (1 << bit)) != 0;
                if (expected) expectedCount++;
                Check(sample.Contains(bit) == expected, "Restore each token flag");
            }
            Check(sample.Count == expectedCount && sample.Encode() == "v1:" + mask, "All token masks round trip");
        }
        restoredTokens.Reset();
        Check(restoredTokens.Count == 0 && restoredTokens.Encode() == "v1:0" && restoredTokens.Collect(7), "Reset makes collected tokens available again");
        Check(CompassMath.Direction(0, 1, 0, 0, 10) == "ahead", "Compass ahead");
        Check(CompassMath.Direction(0, 1, 10, 0, 0) == "right", "Compass right");
        Check(CompassMath.Direction(0, 1, -10, 0, 0) == "left", "Compass left");
        Check(CompassMath.Direction(0, 1, 0, 0, -10) == "behind", "Compass behind");
        Check(CompassMath.Direction(1, 0, 0, 0, 10) == "left", "Compass follows camera rotation");
        Check(CompassMath.Direction(0, 0, 1, 0, 0) == "right", "Compass handles vertical camera");
        Check(CompassMath.Direction(0, 1, 0, 5, 0) == "above" && CompassMath.Direction(0, 1, 0, -5, 0) == "below", "Compass vertical guidance");
        Check(MantleMath.TryLift(10, 11, out float lift) && Math.Abs(lift - 1.12f) < 0.0001f, "Mantle includes foot clearance");
        Check(MantleMath.TryLift(10, 10, out lift) && Math.Abs(lift - 0.12f) < 0.0001f, "Mantle supports a level roof edge");
        Check(MantleMath.TryLift(0, 2.1f, out _), "Mantle accepts maximum rise");
        Check(!MantleMath.TryLift(10, 12.2f, out _) && !MantleMath.TryLift(10, 9.9f, out _), "Mantle rejects distant roofs");
        Check(!MantleMath.TryLift(float.NaN, 1, out _) && !MantleMath.TryLift(1, float.PositiveInfinity, out _), "Mantle rejects invalid heights");
        Check(Math.Abs(SwingMath.ReleaseVerticalSpeed(-10) - 3.2f) < 0.0001f, "Web jump boosts falling player");
        Check(Math.Abs(SwingMath.ReleaseVerticalSpeed(4) - 7.2f) < 0.0001f, "Web jump retains upward momentum");
        Check(Math.Abs(SwingMath.ReleaseVerticalSpeed(11) - 12f) < 0.0001f, "Web jump boost is capped");
        Check(Math.Abs(SwingMath.ReleaseVerticalSpeed(15) - 15f) < 0.0001f, "Web jump does not reduce existing upward speed");
        Check(WebAimMath.TryScore(0, 1, 0, 0, 5, out float straightScore) && Math.Abs(straightScore - 5) < 0.0001, "Web aim targets ahead");
        Check(WebAimMath.TryScore(0, 1, 3, 0, 4, out float sideScore) && sideScore > straightScore, "Web aim prefers centered targets at equal range");
        Check(!WebAimMath.TryScore(0, 1, 5, 0, 0, out _) && !WebAimMath.TryScore(0, 1, 0, 0, -5, out _), "Web aim rejects side and rear targets");
        Check(!WebAimMath.TryScore(0, 1, 0, 0, 14, out _) && !WebAimMath.TryScore(0, 1, 0, 20, 1, out _), "Web aim enforces 3D range");
        Check(!WebAimMath.TryScore(0, 0, 0, 0, 1, out _) && !WebAimMath.TryScore(0, 1, 0, 1, 0, out _) && !WebAimMath.TryScore(0, 1, float.NaN, 0, 1, out _), "Web aim rejects degenerate or invalid vectors");
        var shooter = new WebShooter();
        shooter.Advance(100);
        Check(shooter.Charges == WebShooter.Capacity, "Full web shooter cannot bank recharge");
        Check(!shooter.TryFire(double.NaN) && !shooter.TryFire(double.PositiveInfinity), "Reject invalid web shot times");
        Check(shooter.TryFire(1) && shooter.Charges == 2 && !shooter.TryFire(1.1), "Shot consumes charge and enforces cooldown");
        shooter.Advance(3.99);
        Check(shooter.Charges == 2, "Recharge takes four seconds");
        shooter.Advance(0.02);
        Check(shooter.Charges == 3, "Charge refills after four seconds");
        Check(shooter.TryFire(2) && shooter.TryFire(3) && shooter.TryFire(4) && shooter.Charges == 0, "Shooter can be depleted");
        Check(!shooter.TryFire(5), "Cannot shoot while empty");
        shooter.Advance(-1); shooter.Advance(double.NaN); shooter.Advance(double.PositiveInfinity);
        Check(shooter.Charges == 0, "Invalid elapsed time does not recharge");
        shooter.Advance(8);
        Check(shooter.Charges == 2, "Multiple charges recharge with elapsed time");
        shooter.Advance(50);
        Check(shooter.Charges == 3 && shooter.TryFire(6), "Recharge is capped at capacity");
        shooter.Advance(0.1); shooter.Reset(); shooter.TryFire(7); shooter.Advance(3.99);
        Check(shooter.Charges == 2, "Reset clears stored partial recharge");
        shooter.Reset();
        Check(shooter.Charges == 3 && shooter.TryFire(0), "Reset clears cooldown and restores charges");
        var countdownCrime = new CrimeCycle(0);
        Check(countdownCrime.RemainingSeconds(0) == 0, "No countdown while waiting");
        countdownCrime.Tick(10);
        Check(countdownCrime.RemainingSeconds(10) == 90 && countdownCrime.RemainingSeconds(99.1) == 1 && countdownCrime.RemainingSeconds(100) == 0, "Alert countdown rounds up and clamps");
        Check(countdownCrime.StartEncounter(11) && countdownCrime.RemainingSeconds(11) == 120 && countdownCrime.RemainingSeconds(double.NaN) == 0, "Active countdown and invalid time");
        countdownCrime.Fail(12);
        Check(countdownCrime.RemainingSeconds(12) == 0, "Failed crime clears countdown");
        Console.WriteLine("Story, swing, health, graphics, checkpoints, combat, crime, day-clock, collectible, compass, mantle and web-shot rules passed.");
    }
}
