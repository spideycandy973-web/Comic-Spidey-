using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Two repeatable Free Roam test encounters, not campaign missions or final AI.
    public sealed class PrototypeCrime : MonoBehaviour
    {
        private static readonly Vector3[] Sites = {
            new Vector3(-2, 0, -60), new Vector3(-2, 0, -20),
            new Vector3(-2, 0, 20), new Vector3(-2, 0, 60),
            new Vector3(-60, 0, -2), new Vector3(-20, 0, -2),
            new Vector3(20, 0, -2), new Vector3(60, 0, -2)
        };
        private static readonly Vector3[] SpawnOffsets = {
            new Vector3(-2, 1, 0), new Vector3(2, 1, 0),
            new Vector3(0, 1, -2), new Vector3(0, 1, 2),
            new Vector3(-3, 1, -2), new Vector3(3, 1, 2),
            new Vector3(-3, 1, 2), new Vector3(3, 1, -2)
        };
        private readonly List<PrototypeEnemy> attackers = new List<PrototypeEnemy>();
        private const string ProgressKey = "comicspidey.prototype.crime.completed.v1";
        private const string RescueCountKey = "comicspidey.prototype.crime.rescued.v1";
        private CrimeCycle cycle;
        private CrimeRotation rotation;
        private bool progressWritable, rescueProgressWritable, rescueVariant;
        private int rescuedCount;
        private PrototypeController player;
        private Vector3 site;
        private float nextSpawnAttempt, noticeUntil;
        private string notice = "";
        private GameObject beacon, civilian;
        private Material beaconMaterial, civilianMaterial;
        public bool EncounterActive => cycle != null && cycle.Stage == CrimeStage.Active;
        public bool RescueAvailable => cycle != null && cycle.Stage == CrimeStage.AwaitingRescue;

        private string Guidance(Vector3 destination)
        {
            Vector3 offset = destination - player.transform.position;
            var view = player.CameraView != null ? player.CameraView : player.transform;
            return CompassMath.Direction(view.forward.x, view.forward.z, offset.x, offset.y, offset.z) +
                " " + Mathf.RoundToInt(offset.magnitude) + "m";
        }

        public string Status
        {
            get
            {
                if (cycle == null) return "";
                if (Time.time < noticeUntil) return notice;
                if (cycle.Stage == CrimeStage.Alert)
                    return (rescueVariant ? "Rescue alert — " : "Crime alert — ") + Guidance(site) +
                        " (gold marker) " + cycle.RemainingSeconds(Time.time) + "s";
                if (cycle.Stage == CrimeStage.Active)
                    return (rescueVariant ? "Rescue: stop attackers " : "Stop attackers: ") + cycle.DefeatedCount + "/2 — " + cycle.RemainingSeconds(Time.time) + "s";
                if (cycle.Stage == CrimeStage.AwaitingRescue && civilian != null)
                    return "Reach civilian " + Guidance(civilian.transform.position) + " — " + cycle.RemainingSeconds(Time.time) + "s";
                if (cycle.Stage == CrimeStage.Resolved) return rescueVariant ? "Civilian rescued!" : "Crime stopped!";
                return "Free roam — crimes: " + cycle.ResolvedCount + "  rescues: " + rescuedCount +
                    (progressWritable && rescueProgressWritable ? "" : " (save unavailable)");
            }
        }

        public void Initialize(PrototypeController controller)
        {
            player = controller;
            string saved = PlayerPrefs.GetString(ProgressKey, "");
            int count = 0;
            progressWritable = !PlayerPrefs.HasKey(ProgressKey) || CrimeProgressSave.TryDecode(saved, out count);
            rescuedCount = 0;
            rescueProgressWritable = !PlayerPrefs.HasKey(RescueCountKey) ||
                CrimeProgressSave.TryDecode(PlayerPrefs.GetString(RescueCountKey, ""), out rescuedCount);
            cycle = new CrimeCycle(Time.time, count);
            rotation = new CrimeRotation(Random.Range(0, 2) == 0);
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            beacon = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            beacon.name = "CrimeTestMarker";
            Destroy(beacon.GetComponent<Collider>());
            beacon.transform.localScale = new Vector3(0.6f, 5f, 0.6f);
            if (shader != null)
            {
                beaconMaterial = new Material(shader) { color = new Color(1f, 0.7f, 0.08f) };
                civilianMaterial = new Material(shader) { color = new Color(0.18f, 0.85f, 0.65f) };
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
                // Alternate variants after a random first alert; locations vary separately.
                rescueVariant = rotation.NextIsRescue();
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
                CleanupEncounter();
                notice = "Alert expired";
                noticeUntil = Time.time + 3f;
            }
            if (cycle.Stage != CrimeStage.Alert || Time.time < nextSpawnAttempt) return;
            Vector3 difference = player.transform.position - site;
            if (difference.x * difference.x + difference.z * difference.z > 8f * 8f || Mathf.Abs(difference.y) > 4f) return;
            nextSpawnAttempt = Time.time + 0.5f;
            if (!TryFindSpawnPoints(rescueVariant, out Vector3 first, out Vector3 second, out Vector3 safePerson) ||
                !cycle.StartEncounter(Time.time, rescueVariant)) return;
            beacon.SetActive(false);
            if (rescueVariant) CreateCivilian(safePerson);
            attackers.Add(player.SpawnCrimeEnemy("crime-0", first, OnDefeated));
            attackers.Add(player.SpawnCrimeEnemy("crime-1", second, OnDefeated));
        }

        private bool TryFindSpawnPoints(bool needsPerson, out Vector3 first, out Vector3 second, out Vector3 person)
        {
            first = second = person = Vector3.zero;
            // Check candidate spaces first; do not spawn actors inside other objects.
            var positions = new List<Vector3>();
            foreach (var offset in SpawnOffsets)
            {
                var position = site + offset;
                if (Clear(position)) positions.Add(position);
            }
            for (int i = 0; i < positions.Count; i++)
            for (int j = i + 1; j < positions.Count; j++)
            {
                if ((positions[i] - positions[j]).sqrMagnitude < 4f) continue;
                if (!needsPerson) { first = positions[i]; second = positions[j]; return true; }
                for (int k = 0; k < positions.Count; k++)
                {
                    if (k == i || k == j || (positions[i] - positions[k]).sqrMagnitude < 4f ||
                        (positions[j] - positions[k]).sqrMagnitude < 4f) continue;
                    first = positions[i]; second = positions[j]; person = positions[k]; return true;
                }
            }
            return false;
        }

        private static bool Clear(Vector3 center)
        {
            return !Physics.CheckCapsule(center + Vector3.down * 0.45f, center + Vector3.up * 0.45f,
                0.4f, ~0, QueryTriggerInteraction.Ignore);
        }

        private void CreateCivilian(Vector3 position)
        {
            // A stationary, invulnerable stand-in; no hostage AI or escort yet.
            civilian = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            civilian.name = "RescueTestCivilian";
            civilian.transform.position = position;
            civilian.transform.localScale = new Vector3(0.65f, 0.9f, 0.65f);
            if (civilianMaterial != null) civilian.GetComponent<Renderer>().sharedMaterial = civilianMaterial;
        }

        private void OnDefeated(string id)
        {
            int index = id == "crime-0" ? 0 : id == "crime-1" ? 1 : -1;
            if (!cycle.Defeat(index, Time.time)) return;
            if (cycle.Stage == CrimeStage.AwaitingRescue)
            {
                RemoveAttackers();
                if (civilian != null)
                {
                    beacon.transform.position = civilian.transform.position + Vector3.up * 4f;
                    beacon.SetActive(true);
                }
            }
            else if (cycle.Stage == CrimeStage.Resolved) Finish();
        }

        public void TryRescue()
        {
            if (!RescueAvailable || civilian == null || player == null) return;
            Vector3 origin = player.transform.position + Vector3.up * 0.25f;
            Vector3 delta = civilian.transform.position - origin;
            if (delta.sqrMagnitude > 3f * 3f || !ClearPath(origin, delta))
            {
                notice = "Move closer; clear the path";
                noticeUntil = Time.time + 1.5f;
                return;
            }
            if (cycle.Rescue(Time.time)) Finish();
        }

        private bool ClearPath(Vector3 origin, Vector3 delta)
        {
            float distance = delta.magnitude;
            if (distance < 0.001f) return true;
            foreach (var hit in Physics.RaycastAll(origin, delta / distance, distance, ~0, QueryTriggerInteraction.Ignore))
            {
                if (hit.transform == player.transform || hit.transform.IsChildOf(player.transform) ||
                    hit.transform == civilian.transform || hit.transform.IsChildOf(civilian.transform)) continue;
                return false;
            }
            return true;
        }

        private void Finish()
        {
            if (rescueVariant && rescuedCount < CrimeProgressSave.MaxCompleted) rescuedCount++;
            // Do not overwrite unrecognized data, even though play can continue.
            if (progressWritable) PlayerPrefs.SetString(ProgressKey, CrimeProgressSave.Encode(cycle.ResolvedCount));
            if (rescueVariant && rescueProgressWritable)
                PlayerPrefs.SetString(RescueCountKey, CrimeProgressSave.Encode(rescuedCount));
            if (progressWritable || (rescueVariant && rescueProgressWritable)) PlayerPrefs.Save();
            noticeUntil = 0;
            CleanupEncounter();
        }

        public static void ClearSavedProgress()
        {
            PlayerPrefs.DeleteKey(ProgressKey);
            PlayerPrefs.DeleteKey(RescueCountKey);
            PlayerPrefs.Save();
        }

        public void ResetCount()
        {
            ClearSavedProgress();
            if (cycle != null) cycle.ClearTotal();
            progressWritable = rescueProgressWritable = true;
            rescuedCount = 0;
        }

        public void PlayerDefeated()
        {
            if (cycle == null) return;
            cycle.Fail(Time.time);
            noticeUntil = 0;
            CleanupEncounter();
        }

        private void RemoveAttackers()
        {
            foreach (var actor in attackers) if (actor != null) player.RemoveCrimeEnemy(actor);
            attackers.Clear();
        }

        private void CleanupEncounter()
        {
            RemoveAttackers();
            if (civilian != null) { civilian.SetActive(false); Destroy(civilian); civilian = null; }
            if (beacon != null) beacon.SetActive(false);
        }

        private void OnDestroy()
        {
            if (player != null) CleanupEncounter();
            else { if (civilian != null) Destroy(civilian); }
            if (beacon != null) Destroy(beacon);
            if (beaconMaterial != null) Destroy(beaconMaterial);
            if (civilianMaterial != null) Destroy(civilianMaterial);
        }
    }
}
