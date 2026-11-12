using System.Globalization;

namespace ComicSpidey
{
    // Small, versioned prototype collectible save; independent of campaign data.
    public sealed class CollectibleProgress
    {
        public const int Total = 8;
        private const int AllowedMask = (1 << Total) - 1;
        private int mask;
        public int Count
        {
            get
            {
                int result = 0;
                for (int i = 0; i < Total; i++) if ((mask & (1 << i)) != 0) result++;
                return result;
            }
        }

        public bool Contains(int index) { return index >= 0 && index < Total && (mask & (1 << index)) != 0; }
        public bool Collect(int index)
        {
            if (index < 0 || index >= Total || Contains(index)) return false;
            mask |= 1 << index;
            return true;
        }
        public void Reset() { mask = 0; }
        public string Encode() { return "v1:" + mask.ToString(CultureInfo.InvariantCulture); }
        public static bool TryDecode(string data, out CollectibleProgress progress)
        {
            progress = new CollectibleProgress();
            if (string.IsNullOrEmpty(data) || !data.StartsWith("v1:", System.StringComparison.Ordinal)) return false;
            if (!int.TryParse(data.Substring(3), NumberStyles.None, CultureInfo.InvariantCulture, out int value) ||
                value < 0 || value > AllowedMask) return false;
            progress.mask = value;
            return true;
        }
    }
}
