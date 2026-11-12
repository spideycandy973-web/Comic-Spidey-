namespace ComicSpidey
{
    // Session-only, alternating test alerts ensure both encounters can appear.
    public sealed class CrimeRotation
    {
        private bool nextRescue;
        public CrimeRotation(bool firstIsRescue) { nextRescue = firstIsRescue; }
        public bool NextIsRescue()
        {
            bool result = nextRescue;
            nextRescue = !nextRescue;
            return result;
        }
    }
}
