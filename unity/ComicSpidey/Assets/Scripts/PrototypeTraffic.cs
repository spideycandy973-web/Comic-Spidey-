using UnityEngine;

namespace ComicSpidey
{
    // One slow shuttle along a straight test road. This is not city traffic AI.
    [RequireComponent(typeof(BoxCollider), typeof(Rigidbody))]
    public sealed class PrototypeTraffic : MonoBehaviour
    {
        private BoxCollider body;
        private Rigidbody motor;
        private TrafficRoute route;
        private readonly Collider[] overlaps = new Collider[32];
        private readonly RaycastHit[] casts = new RaycastHit[32];
        private int displayedDirection;

        public void Initialize(float minimum, float maximum, float speed)
        {
            body = GetComponent<BoxCollider>();
            motor = GetComponent<Rigidbody>();
            motor.isKinematic = true;
            motor.useGravity = false;
            route = new TrafficRoute(minimum, maximum, Mathf.Clamp(body.bounds.center.z, minimum, maximum), 1, speed);
            displayedDirection = route.Direction;
        }

        private void FixedUpdate()
        {
            if (route == null || Time.timeScale == 0f) return;
            float step = (float)route.Preview(Time.fixedDeltaTime);
            if (Mathf.Abs(step) < 0.00001f) return;
            bool blocked = IsBlocked(Mathf.Sign(step), Mathf.Abs(step));
            float movement = (float)route.Advance(Time.fixedDeltaTime, blocked);
            if (Mathf.Abs(movement) < 0.00001f) return;
            motor.MovePosition(motor.position + Vector3.forward * movement);
            if (displayedDirection != route.Direction)
            {
                // Rotate in place at the end of the straight route. No turns,
                // traffic lights, wheel animation or dynamic route planning.
                motor.MoveRotation(motor.rotation * Quaternion.Euler(0, 180, 0));
                displayedDirection = route.Direction;
            }
        }

        private bool IsBlocked(float sign, float step)
        {
            // Slightly inset the sensed box to avoid hitting the road under the
            // vehicle; inspect both current overlaps and the entire short path.
            Bounds bounds = body.bounds;
            Vector3 center = bounds.center;
            Vector3 half = bounds.extents;
            half.x = Mathf.Max(0.05f, half.x * 0.9f);
            half.y = Mathf.Max(0.05f, half.y * 0.8f);
            half.z = Mathf.Max(0.05f, half.z * 0.95f);
            Vector3 direction = Vector3.forward * sign;
            // Reuse small buffers to avoid generating garbage every physics tick.
            // If a buffer fills, stop rather than risk overlooking an obstacle.
            int overlapCount = Physics.OverlapBoxNonAlloc(center, half, overlaps, Quaternion.identity, ~0, QueryTriggerInteraction.Ignore);
            if (overlapCount == overlaps.Length) return true;
            for (int i = 0; i < overlapCount; i++) if (IsOther(overlaps[i])) return true;
            int castCount = Physics.BoxCastNonAlloc(center, half, direction, casts, Quaternion.identity,
                step + 0.8f, ~0, QueryTriggerInteraction.Ignore);
            if (castCount == casts.Length) return true;
            for (int i = 0; i < castCount; i++) if (IsOther(casts[i].collider)) return true;
            return false;
        }

        private bool IsOther(Collider hit)
        {
            return hit != null && hit.enabled && hit.transform != transform && !hit.transform.IsChildOf(transform);
        }
    }
}
