using UnityEngine;

namespace ComicSpidey
{
    // Eight floating placeholder markers in the test city, not final collectible
    // models, rewards, missions, or a campaign progression system.
    public sealed class PrototypeCollectibles : MonoBehaviour
    {
        private const string ProgressKey = "comicspidey.prototype.collectibles.v1";
        private static readonly Vector3[] Positions = {
            new Vector3(-2, 1.1f, -25), new Vector3(-2, 1.1f, 55),
            new Vector3(55, 1.1f, -2), new Vector3(-58, 1.1f, -2),
            new Vector3(18, 11.1f, 18), new Vector3(18, 26.1f, -22),
            new Vector3(-22, 16.1f, 18), new Vector3(58, 16.1f, 18)
        };
        private readonly GameObject[] markers = new GameObject[CollectibleProgress.Total];
        private readonly bool[] waitForExit = new bool[CollectibleProgress.Total];
        private CollectibleProgress progress;
        private Material material;
        private bool progressWritable;
        private Transform player;
        private Transform cameraView;
        private float lastCollectUntil;

        public void Initialize(Transform playerTransform, Transform view)
        {
            player = playerTransform;
            cameraView = view;
            var saved = PlayerPrefs.GetString(ProgressKey, "");
            progressWritable = !PlayerPrefs.HasKey(ProgressKey) || CollectibleProgress.TryDecode(saved, out progress);
            if (progress == null) progress = new CollectibleProgress();
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            if (shader != null) material = new Material(shader) { color = new Color(0.1f, 0.94f, 1f) };
            for (int i = 0; i < markers.Length; i++)
            {
                var marker = GameObject.CreatePrimitive(PrimitiveType.Sphere);
                marker.name = "CollectibleTestMarker" + i;
                marker.transform.position = Positions[i];
                marker.transform.localScale = Vector3.one * 0.8f;
                var collider = marker.GetComponent<Collider>();
                collider.enabled = false;
                Destroy(collider);
                if (material != null) marker.GetComponent<Renderer>().sharedMaterial = material;
                marker.SetActive(!progress.Contains(i));
                markers[i] = marker;
            }
        }

        private void Update()
        {
            if (progress == null || player == null || Time.timeScale == 0f) return;
            for (int i = 0; i < markers.Length; i++)
            {
                var marker = markers[i];
                if (marker == null || !marker.activeSelf) continue;
                marker.transform.position = Positions[i] + Vector3.up * (0.14f * Mathf.Sin(Time.time * 2f + i));
                float distance = (player.position - marker.transform.position).sqrMagnitude;
                if (waitForExit[i])
                {
                    if (distance <= 2.2f * 2.2f) continue;
                    waitForExit[i] = false;
                }
                if (distance > 1.6f * 1.6f) continue;
                // Do not collect a marker through a nearby wall or ceiling.
                if (Physics.Linecast(player.position, marker.transform.position, ~0, QueryTriggerInteraction.Ignore)) continue;
                if (!progress.Collect(i)) continue;
                marker.SetActive(false);
                lastCollectUntil = Time.time + 2f;
                if (progressWritable)
                {
                    PlayerPrefs.SetString(ProgressKey, progress.Encode());
                    PlayerPrefs.Save();
                }
            }
        }

        public string Status
        {
            get
            {
                if (progress == null) return "";
                string text = "Tokens " + progress.Count + "/" + CollectibleProgress.Total;
                if (!progressWritable) text += " (save unavailable)";
                if (Time.time < lastCollectUntil) return text + " — found!";
                if (progress.Count == CollectibleProgress.Total) return text + " — all found";
                int nearest = -1;
                float nearestDistance = float.MaxValue;
                for (int i = 0; i < Positions.Length; i++)
                {
                    if (progress.Contains(i)) continue;
                    float distance = (Positions[i] - player.position).sqrMagnitude;
                    if (distance < nearestDistance) { nearestDistance = distance; nearest = i; }
                }
                if (nearest < 0) return text;
                Vector3 offset = Positions[nearest] - player.position;
                Vector3 forward = cameraView != null ? cameraView.forward : player.forward;
                string direction = CompassMath.Direction(forward.x, forward.z, offset.x, offset.y, offset.z);
                return text + " — nearest " + direction + " " + Mathf.RoundToInt(Mathf.Sqrt(nearestDistance)) + "m";
            }
        }

        public static void ClearSavedProgress()
        {
            PlayerPrefs.DeleteKey(ProgressKey);
            PlayerPrefs.Save();
        }

        public void ResetProgress()
        {
            ClearSavedProgress();
            progress.Reset();
            progressWritable = true;
            lastCollectUntil = 0;
            for (int i = 0; i < markers.Length; i++)
            {
                if (markers[i] == null) continue;
                // A reset while standing on a token shouldn't instantly pick it up again.
                waitForExit[i] = player != null && (player.position - Positions[i]).sqrMagnitude <= 2.2f * 2.2f;
                markers[i].SetActive(true);
            }
        }

        private void OnDestroy()
        {
            foreach (var marker in markers) if (marker != null) Destroy(marker);
            if (material != null) Destroy(material);
        }
    }
}
