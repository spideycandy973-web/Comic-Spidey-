using System;

namespace ComicSpidey
{
    // Fixed options with clamping so old/corrupt local preferences remain safe.
    public sealed class GraphicsOptionsData
    {
        public static readonly string[] QualityNames = { "Low", "Balanced", "High", "Ultra" };
        public static readonly int[] FrameRates = { 30, 60, 120 };
        public static readonly int[] ResolutionPercent = { 50, 75, 100 };
        public int Quality { get; private set; }
        public int FrameRateIndex { get; private set; }
        public int ResolutionIndex { get; private set; }
        public bool Shadows { get; private set; }

        public GraphicsOptionsData(int quality, int fps, int resolution, bool shadows)
        {
            Quality = Clamp(quality, QualityNames.Length);
            FrameRateIndex = Clamp(fps, FrameRates.Length);
            ResolutionIndex = Clamp(resolution, ResolutionPercent.Length);
            Shadows = shadows;
        }
        private static int Clamp(int value, int count) { return Math.Max(0, Math.Min(count - 1, value)); }
        public void CycleQuality() { Quality = (Quality + 1) % QualityNames.Length; }
        public void CycleFrameRate() { FrameRateIndex = (FrameRateIndex + 1) % FrameRates.Length; }
        public void CycleResolution() { ResolutionIndex = (ResolutionIndex + 1) % ResolutionPercent.Length; }
        public void ToggleShadows() { Shadows = !Shadows; }
    }
}
