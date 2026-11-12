using UnityEngine;

namespace ComicSpidey
{
    // All choices are prototypes; none represents a finished game mode.
    public sealed class PrototypeModeMenu : MonoBehaviour
    {
        private PrototypeController controller;
        private PrototypeSettings settings;
        private GameObject marker;
        private float previousTimeScale;
        public bool IsChoosing { get; private set; }

        public void Initialize(PrototypeController player, PrototypeSettings graphics, GameObject objectiveMarker)
        {
            controller = player;
            settings = graphics;
            marker = objectiveMarker;
            IsChoosing = true;
            previousTimeScale = Time.timeScale;
            Time.timeScale = 0f;
            if (settings != null) settings.SetAvailable(false);
            if (marker != null) marker.SetActive(false);
        }

        private void Select(int mode)
        {
            if (!IsChoosing) return;
            if (controller != null) controller.StartMode(mode);
            if (marker != null) marker.SetActive(mode == 0);
            IsChoosing = false;
            Time.timeScale = previousTimeScale;
            if (settings != null) settings.SetAvailable(true);
        }

        private void OnDestroy() { if (IsChoosing) Time.timeScale = previousTimeScale; }

        private void OnGUI()
        {
            if (!IsChoosing) return;
            GUI.depth = -20;
            GUI.Box(new Rect(0, 0, Screen.width, Screen.height), "");
            float unit = Mathf.Min(Screen.width, Screen.height);
            var label = new GUIStyle(GUI.skin.label) { fontSize = Mathf.Max(16, Mathf.RoundToInt(unit * 0.045f)), alignment = TextAnchor.MiddleCenter, wordWrap = true };
            var button = new GUIStyle(GUI.skin.button) { fontSize = Mathf.Max(16, Mathf.RoundToInt(unit * 0.04f)), wordWrap = true };
            float x = Screen.width * 0.2f, width = Screen.width * 0.6f;
            GUI.Label(new Rect(x, Screen.height * 0.04f, width, Screen.height * 0.13f), "COMIC SPIDEY — OFFLINE TEST", label);
            if (GUI.Button(new Rect(x, Screen.height * 0.20f, width, Screen.height * 0.13f), "STORY TEST", button)) Select(0);
            if (GUI.Button(new Rect(x, Screen.height * 0.37f, width, Screen.height * 0.13f), "FREE ROAM TEST", button)) Select(1);
            if (GUI.Button(new Rect(x, Screen.height * 0.54f, width, Screen.height * 0.13f), "BOSS TEST", button)) Select(2);
            GUI.Label(new Rect(x, Screen.height * 0.72f, width, Screen.height * 0.15f), "Prototype tests only; full game is in development.", label);
        }
    }
}
