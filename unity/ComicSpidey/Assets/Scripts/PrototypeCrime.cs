using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Repeatable, isolated free-roam encounter. This is not a campaign mission
    // or the final random-crime, police, rescue or progression system.
    public sealed class PrototypeCrime : MonoBehaviour
    {
        private static readonly Vector3[] Sites = {
            new Vector3(-2, 0, -60), new Vector3(-2, 0, -20),
            new Vector3(-2, 0, 20), new Vector3(-2, 0, 60),
            new Vector3(-60, 0, -2), new Vector3(-20, 0, -2),
            new Vector3(20, 0, -2), new Vector3(60, 0, -2)
        };
        private readonly List<PrototypeEnemy> attackers = new List<PrototypeEnemy>();
        private const string ProgressKey = "comicspidey.prototype.crime.completed.v1";
        private CrimeCycle cycle;
        private bool progressWritable;
        private PrototypeController player;
        private Vector3 site;
        private float nextSpawnAttempt;
        private GameObject beacon;
        private Material beaconMaterial;
        public bool EncounterActive => cycle != null && cycle.Stage == CrimeStage.Active;

        public string Status
        {
            get
            {
                if (cycle == null) return "";
                if (cycle.Stage == CrimeStage.Alert)
                {
                    Vector3 offset = site - player.transform.position;
                    var view = player.CameraView != null ? player.CameraView : player.transform;
                    string direction = CompassMath.Direction(view.forward.x, view.forward.z, offset.x, offset.y, offset.z);
                    int distance = Mathf.RoundToInt(offset.magnitude);
                    return "Crime — " + direction + " " + distance + "m (gold marker) " + cycle.RemainingSeconds(Time.time) + "s";
                }
                if (cycle.Stage == CrimeStage.Active) return "Stop attackers " + cycle.DefeatedCount + "/2 — " + cycle.RemainingSeconds(Time.time) + "s";
                if (cycle.Stage == CrimeStage.Resolved) return "Crime stopped!";
                return "Free roam — crimes stopped: " + cycle.ResolvedCount + (progressWritable ? "" : " (save unavailable)");
            }
        }

        public void Initialize(PrototypeController controller)
        {
            player = controller;
            string saved = PlayerPrefs.GetString(ProgressKey, "");
            int count = 0;
            progressWritable = !PlayerPrefs.HasKey(ProgressKey) || CrimeProgressSave.TryDecode(saved, out count);
            cycle = new CrimeCycle(Time.time, count);
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            beacon = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            beacon.name = "CrimeTestMarker";
            Destroy(beacon.GetComponent<Collider>());
            beacon.transform.localScale = new Vector3(0.6f, 5f, 0.6f);
            if (shader != null)
            {
                beaconMaterial = new Material(shader) { color = new Color(1f, 0.7f, 0.08f) };
                beacon.GetComponent<Renderer>().sharedMaterial = beaconMaterial;
            }
            beacon.SetActive(false);
        }

        private void Update()
        {
            if (cycle == null || player == null || Time.timeScale == 0f) return;
            CrimeEvent change = cycle.Tick(Time.time);
            if (change == CrimeEvent.AlertStarted)
            {
                // Rotate through candidate streets from a random starting point,
                // avoiding an alert right under the player or outside the city.
                int start = Random.Range(0, Sites.Length);
                bool found = false;
                for (int i = 0; i < Sites.Length; i++)
                {
                    var candidate = Sites[(start + i) % Sites.Length];
                    Vector3 flat = candidate - player.transform.position;
                    flat.y = 0;
                    if (flat.sqrMagnitude < 22f * 22f || flat.sqrMagnitude > 160f * 160f) continue;
                    site = candidate;
                    found = true;
                    break;
                }
                if (!found) { cycle.Fail(Time.time); return; }
                beacon.transform.position = site + Vector3.up * 5f;
                beacon.SetActive(true);
            }
            if (change == CrimeEvent.Expired)
            {
                RemoveAttackers();
                beacon.SetActive(false);
            }
            if (cycle.Stage != CrimeStage.Alert || Time.time < nextSpawnAttempt) return;
            Vector3 difference = player.transform.position - site;
            if (difference.x * difference.x + difference.z * difference.z > 8f * 8f || Mathf.Abs(difference.y) > 4f) return;
            nextSpawnAttempt = Time.time + 0.5f;
            if (!TryFindSpawnPoints(out Vector3 first, out Vector3 second) || !cycle.StartEncounter(Time.time)) return;
            beacon.SetActive(false);
            attackers.Add(player.SpawnCrimeEnemy("crime-0", first, OnDefeated));
            attackers.Add(player.SpawnCrimeEnemy("crime-1", second, OnDefeated));
        }

        private bool TryFindSpawnPoints(out Vector3 first, out Vector3 second)
        {
            first = second = Vector3.zero;
            Vector3[] offsets = { new Vector3(-2, 1, 0), new Vector3(2, 1, 0),
                new Vector3(0, 1, -2), new Vector3(0, 1, 2),
                new Vector3(-3, 1, -2), new Vector3(3, 1, 2) };
            bool hasFirst = false;
            foreach (var offset in offsets)
            {
                var position = site + offset;
                if (!Clear(position)) continue;
                if (!hasFirst) { first = position; hasFirst = true; }
                else if ((position - first).sqrMagnitude >= 2f * 2f) { second = position; return true; }
            }
            return false;
        }

        private static bool Clear(Vector3 center)
        {
            // Ground-level capsule check; reject obstacles, cars and actors.
            return !Physics.CheckCapsule(center + Vector3.down * 0.45f, center + Vector3.up * 0.45f,
                0.4f, ~0, QueryTriggerInteraction.Ignore);
        }

        private void OnDefeated(string id)
        {
            int index = id == "crime-0" ? 0 : id == "crime-1" ? 1 : -1;
            if (!cycle.Defeat(index, Time.time)) return;
            if (cycle.Stage == CrimeStage.Resolved)
            {
                // Never overwrite an unrecognised/corrupted or future save.
                if (progressWritable)
                {
                    PlayerPrefs.SetString(ProgressKey, CrimeProgressSave.Encode(cycle.ResolvedCount));
                    PlayerPrefs.Save();
                }
                RemoveAttackers();
            }
        }

        public static void ClearSavedProgress()
        {
            PlayerPrefs.DeleteKey(ProgressKey);
            PlayerPrefs.Save();
        }

        public void ResetCount()
        {
            ClearSavedProgress();
            if (cycle != null) cycle.ClearTotal();
            progressWritable = true;
        }

        public void PlayerDefeated()
        {
            if (cycle == null) return;
            cycle.Fail(Time.time);
            RemoveAttackers();
            if (beacon != null) beacon.SetActive(false);
        }

        private void RemoveAttackers()
        {
            foreach (var actor in attackers) if (actor != null) player.RemoveCrimeEnemy(actor);
            attackers.Clear();
        }

        private void OnDestroy()
        {
            if (player != null) RemoveAttackers();
            if (beacon != null) Destroy(beacon);
            if (beaconMaterial != null) Destroy(beaconMaterial);
        }
    }
}
