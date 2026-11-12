using System;

namespace ComicSpidey
{
    // A bounded, session-only shuttle route. Unity handles collision sensing.
    public sealed class TrafficRoute
    {
        public double Position { get; private set; }
        public int Direction { get; private set; }
        public double Minimum { get; }
        public double Maximum { get; }
        public double Speed { get; }

        public TrafficRoute(double minimum, double maximum, double position, int direction, double speed)
        {
            if (!Finite(minimum) || !Finite(maximum) || minimum >= maximum ||
                !Finite(position) || position < minimum || position > maximum ||
                (direction != 1 && direction != -1) || !Finite(speed) || speed <= 0)
                throw new ArgumentOutOfRangeException();
            Minimum = minimum; Maximum = maximum; Position = position; Speed = speed;
            Direction = position == minimum ? 1 : position == maximum ? -1 : direction;
        }

        // Preview without advancing, so the caller can check the full path first.
        public double Preview(double seconds)
        {
            if (!Finite(seconds) || seconds <= 0) return 0;
            double distance = Math.Min(Speed * seconds, Direction > 0 ? Maximum - Position : Position - Minimum);
            return Direction * distance;
        }

        public double Advance(double seconds, bool blocked)
        {
            if (blocked) return 0;
            double step = Preview(seconds);
            if (step == 0) return 0;
            Position = Math.Max(Minimum, Math.Min(Maximum, Position + step));
            if (Position >= Maximum) Direction = -1;
            else if (Position <= Minimum) Direction = 1;
            return step;
        }

        private static bool Finite(double value) => !double.IsNaN(value) && !double.IsInfinity(value);
    }
}
