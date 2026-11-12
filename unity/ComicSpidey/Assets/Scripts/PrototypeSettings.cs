using UnityEngine;

namespace ComicSpidey
{
    // Runtime prototype options, not a claim that every GPU supports every mode.
    public sealed class PrototypeSettings : MonoBehaviour
    {
        private const string Prefix = "comicspidey.prototype.graphics.";
        private GraphicsOptionsData options;
        private Light sun;
        private Camera view;
        private bool confirmReset, confirmCrimeReset, confirmCollectibleReset;
        private bool available = true;
        public bool IsOpen { get; private set; }
        private float previousTimeScale = 1f;

        // GUI coordinates have a top-left origin; touches are bottom-left.
        private Rect MenuButton => new Rect(Screen.width - Screen.height * 0.22f,
            Screen.height * 0.03f, Screen.height * 0.19f, Screen.height * 0.10f);
        public bool BlocksTouch(Vector2 point)
        {
            return IsOpen || MenuButton.Contains(new Vector2(point.x, Screen.height - point.y));
        }

        public void SetAvailable(bool value) { available = value; }

        public void Initialize(Camera cameraView, Light sunLight)
        {
            view = cameraView;
            sun = sunLight;
            options = new GraphicsOptionsData(PlayerPrefs.GetInt(Prefix + "quality", 1),
                PlayerPrefs.GetInt(Prefix + "fps", 1), PlayerPrefs.GetInt(Prefix + "resolution", 1),
                PlayerPrefs.GetInt(Prefix + "shadows", 1) != 0);
            Apply();
        }

        private void Apply()
        {
            QualitySettings.vSyncCount = 0;
            Application.targetFrameRate = GraphicsOptionsData.FrameRates[options.FrameRateIndex];
            QualitySettings.masterTextureLimit = options.Quality == 0 ? 2 : options.Quality == 1 ? 1 : 0;
            QualitySettings.shadowDistance = new float[] { 15, 30, 50, 75 }[options.Quality];
            QualitySettings.shadowResolution = options.Quality < 2 ? ShadowResolution.Low : ShadowResolution.High;
            QualitySettings.shadows = options.Shadows ? ShadowQuality.All : ShadowQuality.Disable;
            if (sun != null) sun.shadows = options.Shadows ? LightShadows.Hard : LightShadows.None;
            if (view != null) view.allowDynamicResolution = true;
            float scale = GraphicsOptionsData.ResolutionPercent[options.ResolutionIndex] / 100f;
            ScalableBufferManager.ResizeBuffers(scale, scale);
            PlayerPrefs.SetInt(Prefix + "quality", options.Quality);
            PlayerPrefs.SetInt(Prefix + "fps", options.FrameRateIndex);
            PlayerPrefs.SetInt(Prefix + "resolution", options.ResolutionIndex);
            PlayerPrefs.SetInt(Prefix + "shadows", options.Shadows ? 1 : 0);
            PlayerPrefs.Save();
        }

        private void SetOpen(bool open)
        {
            if (IsOpen == open) return;
            if (open) { previousTimeScale = Time.timeScale; Time.timeScale = 0f; }
            else { Time.timeScale = previousTimeScale; confirmReset = confirmCrimeReset = confirmCollectibleReset = false; }
            IsOpen = open;
        }

        private void OnDestroy() { if (IsOpen) Time.timeScale = previousTimeScale; }

        private void OnGUI()
        {
            if (options == null || !available) return;
            GUI.depth = -10;
            float unit = Mathf.Min(Screen.width, Screen.height);
            var button = new GUIStyle(GUI.skin.button) { fontSize = Mathf.Max(16, Mathf.RoundToInt(unit * 0.035f)), wordWrap = true };
            var text = new GUIStyle(GUI.skin.label) { fontSize = Mathf.Max(14, Mathf.RoundToInt(unit * 0.03f)), wordWrap = true, alignment = TextAnchor.MiddleCenter };
            if (!IsOpen)
            {
                if (GUI.Button(MenuButton, "SETTINGS", button)) SetOpen(true);
                return;
            }
            GUI.Box(new Rect(0, 0, Screen.width, Screen.height), "");
            float x = Screen.width * 0.2f, width = Screen.width * 0.6f, h = Screen.height * 0.09f;
            float y = Screen.height * 0.035f, gap = Screen.height * 0.014f;
            if (GUI.Button(new Rect(x, y, width, h), "Quality: " + GraphicsOptionsData.QualityNames[options.Quality], button)) { options.CycleQuality(); Apply(); }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), "Frame rate target: " + GraphicsOptionsData.FrameRates[options.FrameRateIndex], button)) { options.CycleFrameRate(); Apply(); }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), "Render scale: " + GraphicsOptionsData.ResolutionPercent[options.ResolutionIndex] + "%", button)) { options.CycleResolution(); Apply(); }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), "Shadows: " + (options.Shadows ? "On" : "Off"), button)) { options.ToggleShadows(); Apply(); }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), confirmReset ? "CONFIRM RESET TEST PROGRESS" : "RESET TEST PROGRESS", button))
            {
                if (!confirmReset) { confirmReset = true; confirmCrimeReset = confirmCollectibleReset = false; }
                else
                {
                    var controller = GetComponent<PrototypeController>();
                    if (controller != null) controller.ResetTestProgress();
                    SetOpen(false);
                }
            }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), confirmCrimeReset ? "CONFIRM RESET CRIME + RESCUE COUNTS" : "RESET CRIME + RESCUE COUNTS", button))
            {
                if (!confirmCrimeReset) { confirmCrimeReset = true; confirmReset = confirmCollectibleReset = false; }
                else
                {
                    var controller = GetComponent<PrototypeController>();
                    if (controller != null) controller.ResetCrimeProgress();
                    SetOpen(false);
                }
            }
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), confirmCollectibleReset ? "CONFIRM RESET TOKENS" : "RESET TEST TOKENS", button))
            {
                if (!confirmCollectibleReset) { confirmCollectibleReset = true; confirmReset = confirmCrimeReset = false; }
                else
                {
                    var controller = GetComponent<PrototypeController>();
                    if (controller != null) controller.ResetCollectibleProgress();
                    SetOpen(false);
                }
            }
            y += h + gap;
            GUI.Label(new Rect(x, y, width, h), "FPS and render scale depend on your device.", text);
            y += h + gap;
            if (GUI.Button(new Rect(x, y, width, h), "RESUME", button)) SetOpen(false);
        }
    }
}
