using System;
using System.Globalization;

namespace ComicSpidey
{
    // This small, versioned checkpoint is only for the two-enemy test encounter.
    // It is deliberately separate from the future 25-mission campaign saves.
    public sealed class PrototypeCheckpoint
    {
        public int Phase { get; private set; } // 0: travel, 1: encounter, 2: test complete
        public int DefeatedMask { get; private set; }

        public void StartEncounter()
        {
            if (Phase == 0) Phase = 1;
        }

        public bool MarkDefeated(int index)
        {
            if (Phase != 1 || index < 0 || index > 1) return false;
            int bit = 1 << index;
            if ((DefeatedMask & bit) != 0) return false;
            DefeatedMask |= bit;
            if (DefeatedMask == 3) Phase = 2;
            return true;
        }

        public bool IsDefeated(int index)
        {
            return index >= 0 && index <= 1 && (DefeatedMask & (1 << index)) != 0;
        }

        public string Encode() { return "v1:" + Phase + ":" + DefeatedMask; }

        public static bool TryDecode(string value, out PrototypeCheckpoint checkpoint)
        {
            checkpoint = null;
            if (string.IsNullOrEmpty(value)) return false;
            string[] parts = value.Split(':');
            if (parts.Length != 3 || parts[0] != "v1" ||
                !int.TryParse(parts[1], NumberStyles.None, CultureInfo.InvariantCulture, out int phase) ||
                !int.TryParse(parts[2], NumberStyles.None, CultureInfo.InvariantCulture, out int mask)) return false;
            if (!((phase == 0 && mask == 0) || (phase == 1 && mask >= 0 && mask <= 2) ||
                (phase == 2 && mask == 3))) return false;
            checkpoint = new PrototypeCheckpoint { Phase = phase, DefeatedMask = mask };
            return true;
        }
    }
}
