using System.Globalization;

namespace ComicSpidey
{
    // Separate from campaign saves and the story-test encounter checkpoint.
    public static class CrimeProgressSave
    {
        public const int MaxCompleted = 1000000;
        public static string Encode(int completed)
        {
            if (completed < 0 || completed > MaxCompleted) throw new System.ArgumentOutOfRangeException(nameof(completed));
            return "v1:" + completed.ToString(CultureInfo.InvariantCulture);
        }

        public static bool TryDecode(string data, out int completed)
        {
            completed = 0;
            if (string.IsNullOrEmpty(data) || !data.StartsWith("v1:", System.StringComparison.Ordinal)) return false;
            string value = data.Substring(3);
            if (value.Length == 0 || !int.TryParse(value, NumberStyles.None, CultureInfo.InvariantCulture, out int result) ||
                result < 0 || result > MaxCompleted) return false;
            completed = result;
            return true;
        }
    }
}
