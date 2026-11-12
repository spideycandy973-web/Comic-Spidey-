using UnityEngine;
using UnityEngine.Rendering;

namespace ComicSpidey
{
    // Low-cost lighting/sky colour experiment for the small test city. This
    // is not final sky rendering, weather, or a saved world time.
    public sealed class PrototypeDayNight : MonoBehaviour
    {
        private readonly DayNightClock clock = new DayNightClock(0.42);
        private Light sun;
        private Camera view;

        public void Initialize(Light directionalLight, Camera cameraView)
        {
            sun = directionalLight;
            view = cameraView;
            RenderSettings.ambientMode = AmbientMode.Flat;
            if (view != null) view.clearFlags = CameraClearFlags.SolidColor;
            Apply();
        }

        private void Update()
        {
            if (sun == null || view == null || Time.timeScale == 0f) return;
            clock.Advance(Time.deltaTime);
            Apply();
        }

        private void Apply()
        {
            if (sun == null || view == null) return;
            float phase = (float)clock.Phase;
            float altitude = Mathf.Sin((phase - 0.25f) * Mathf.PI * 2f);
            float daylight = Mathf.SmoothStep(0f, 1f, Mathf.InverseLerp(-0.12f, 0.26f, altitude));
            float twilight = (1f - Mathf.Clamp01(Mathf.Abs(altitude) * 3f)) * daylight;
            sun.transform.rotation = Quaternion.Euler(phase * 360f - 90f, -35f, 0f);
            sun.intensity = Mathf.Lerp(0.16f, 1f, daylight);
            sun.color = Color.Lerp(new Color(0.53f, 0.67f, 1f), Color.white, daylight);
            sun.color = Color.Lerp(sun.color, new Color(1f, 0.63f, 0.42f), twilight * 0.7f);
            RenderSettings.ambientLight = Color.Lerp(new Color(0.16f, 0.20f, 0.34f), new Color(0.58f, 0.59f, 0.64f), daylight);
            Color sky = Color.Lerp(new Color(0.035f, 0.045f, 0.11f), new Color(0.45f, 0.68f, 0.88f), daylight);
            view.backgroundColor = Color.Lerp(sky, new Color(0.91f, 0.43f, 0.43f), twilight * 0.55f);
        }
    }
}
