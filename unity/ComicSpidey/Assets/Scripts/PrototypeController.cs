using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    [RequireComponent(typeof(CharacterController))]
    public sealed class PrototypeController : MonoBehaviour
    {
        private CharacterController motor;
        private Transform cameraTransform;
        private List<Transform> anchors;
        private Vector3 velocity;
        private Transform webAnchor;
        private float ropeLength;
        private float yaw = 0f;
        private float pitch = 18f;
        private int joystickFinger = -1, lookFinger = -1, webFinger = -1;
        private Vector2 joystickOrigin, moveInput;
        private bool jumpRequested;
        private bool trackingMouse;
        private Vector3 lastMouse;
        private LineRenderer webLine;
        private HeroVisual heroVisual;
        private readonly StoryProgress story = new StoryProgress();

        public void Initialize(Transform cameraView, List<Transform> webAnchors)
        {
            motor = GetComponent<CharacterController>();
            heroVisual = GetComponent<HeroVisual>();
            cameraTransform = cameraView;
            anchors = webAnchors;
            webLine = gameObject.AddComponent<LineRenderer>();
            webLine.material = new Material(Resources.Load<Shader>("Hero/HeroLit"));
            webLine.startColor = webLine.endColor = Color.white;
            webLine.startWidth = webLine.endWidth = 0.04f;
            webLine.positionCount = 2;
            webLine.enabled = false;
        }

        // Use viewport-relative sizes so the touch targets scale on phones.
        private float ButtonSize => Mathf.Min(Screen.height * 0.17f, Screen.width * 0.12f);
        private float ButtonMargin => Mathf.Max(12f, Screen.height * 0.03f);
        private Rect JumpRect => new Rect(Screen.width - ButtonMargin - ButtonSize, ButtonMargin, ButtonSize, ButtonSize);
        private Rect WebRect => new Rect(JumpRect.x, JumpRect.yMax + ButtonMargin, ButtonSize, ButtonSize);

        private void Update()
        {
            if (cameraTransform == null) return;
            HandleInput();
            var heading = Quaternion.Euler(0, yaw, 0);
            var desired = heading * new Vector3(moveInput.x, 0, moveInput.y);
            if (desired.sqrMagnitude > 1) desired.Normalize();
            if (motor.isGrounded && velocity.y < 0) velocity.y = -2f;
            if (jumpRequested && motor.isGrounded) velocity.y = 8f;
            jumpRequested = false;
            velocity.y -= 20f * Time.deltaTime;
            Vector3 horizontal = new Vector3(velocity.x, 0, velocity.z);
            // Do not overwrite horizontal velocity while airborne: release from
            // the tether should retain momentum rather than stopping instantly.
            if (motor.isGrounded || desired.sqrMagnitude > 0.001f)
                horizontal = Vector3.MoveTowards(horizontal, desired * 7f, (motor.isGrounded ? 28f : 4f) * Time.deltaTime);
            velocity.x = horizontal.x;
            velocity.z = horizontal.z;

            // An intentionally simple tether prototype, not a finished swing system.
            if (webAnchor != null)
            {
                Vector3 rope = transform.position - webAnchor.position;
                if (rope.magnitude > ropeLength && Vector3.Dot(velocity, rope) > 0)
                    velocity -= Vector3.Project(velocity, rope);
            }
            var collisions = motor.Move(velocity * Time.deltaTime);
            if ((collisions & CollisionFlags.Above) != 0 && velocity.y > 0) velocity.y = 0;
            if ((collisions & CollisionFlags.Below) != 0 && velocity.y < 0) velocity.y = -2f;
            story.Visit(transform.position.x, transform.position.y - 1f, transform.position.z);
            if (webAnchor != null)
            {
                Vector3 rope = transform.position - webAnchor.position;
                if (rope.magnitude > ropeLength)
                    motor.Move(-rope.normalized * (rope.magnitude - ropeLength));
                webLine.enabled = true;
                webLine.SetPosition(0, transform.position + Vector3.up * 0.5f);
                webLine.SetPosition(1, webAnchor.position);
            }
            else webLine.enabled = false;
            if (heroVisual != null) heroVisual.UpdateMotion(motor.isGrounded, webAnchor != null, velocity);
            if (desired.sqrMagnitude > 0.01f)
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(desired), 12f * Time.deltaTime);
        }

        private void LateUpdate()
        {
            if (cameraTransform == null) return;
            Quaternion rotation = Quaternion.Euler(pitch, yaw, 0);
            Vector3 focus = transform.position + Vector3.up * 1.2f;
            Vector3 desired = focus - rotation * Vector3.forward * 6f;
            // Keep the camera in front of walls where possible.
            if (Physics.Linecast(focus, desired, out RaycastHit hit, ~0, QueryTriggerInteraction.Ignore))
                desired = hit.point + hit.normal * 0.2f;
            cameraTransform.position = desired;
            cameraTransform.rotation = rotation;
        }

        private void HandleInput()
        {
            if (Input.touchCount == 0 && joystickFinger == -1 && webFinger == -1 && lookFinger == -1)
            {
                moveInput = new Vector2((Input.GetKey(KeyCode.D) ? 1 : 0) - (Input.GetKey(KeyCode.A) ? 1 : 0),
                    (Input.GetKey(KeyCode.W) ? 1 : 0) - (Input.GetKey(KeyCode.S) ? 1 : 0));
                if (Input.GetKeyDown(KeyCode.Space)) jumpRequested = true;
                if (Input.GetMouseButton(1))
                {
                    Vector3 mouse = Input.mousePosition;
                    if (trackingMouse)
                    {
                        Vector3 delta = mouse - lastMouse;
                        yaw += delta.x * 0.16f;
                        pitch = Mathf.Clamp(pitch - delta.y * 0.16f, -25, 65);
                    }
                    lastMouse = mouse;
                    trackingMouse = true;
                }
                else trackingMouse = false;
                if (Input.GetKeyDown(KeyCode.E)) AttachWeb();
                if (Input.GetKeyUp(KeyCode.E)) webAnchor = null;
            }
            foreach (Touch touch in Input.touches)
            {
                Vector2 p = touch.position; // Touch positions have a bottom-left origin.
                if (touch.phase == TouchPhase.Began)
                {
                    if (JumpRect.Contains(p)) jumpRequested = true;
                    else if (WebRect.Contains(p) && webFinger == -1) { webFinger = touch.fingerId; AttachWeb(); }
                    else if (p.x < Screen.width * 0.45f && joystickFinger == -1) { joystickFinger = touch.fingerId; joystickOrigin = p; moveInput = Vector2.zero; }
                    else if (lookFinger == -1) lookFinger = touch.fingerId;
                }
                if (touch.fingerId == joystickFinger)
                    moveInput = Vector2.ClampMagnitude((p - joystickOrigin) / 70f, 1f);
                if (touch.fingerId == lookFinger && touch.phase == TouchPhase.Moved)
                {
                    yaw += touch.deltaPosition.x * 0.16f;
                    pitch = Mathf.Clamp(pitch - touch.deltaPosition.y * 0.16f, -25, 65);
                }
                if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
                {
                    if (touch.fingerId == joystickFinger) { joystickFinger = -1; moveInput = Vector2.zero; }
                    if (touch.fingerId == lookFinger) lookFinger = -1;
                    if (touch.fingerId == webFinger) { webFinger = -1; webAnchor = null; }
                }
            }
        }

        private void AttachWeb()
        {
            Transform nearest = null;
            float best = 38f;
            foreach (Transform anchor in anchors)
            {
                float distance = Vector3.Distance(transform.position, anchor.position);
                if (distance < best) { best = distance; nearest = anchor; }
            }
            webAnchor = nearest;
            if (webAnchor != null) ropeLength = best;
        }

        private void OnApplicationFocus(bool focus)
        {
            if (focus) return;
            joystickFinger = lookFinger = webFinger = -1;
            moveInput = Vector2.zero;
            webAnchor = null;
            jumpRequested = false;
            trackingMouse = false;
        }

        private void OnGUI()
        {
            GUI.Box(new Rect(12, 12, 420, 46), "UNITY PROTOTYPE - " + story.Current.Title);
            if (story.Current.Kind == ObjectiveKind.Fight)
                GUI.Label(new Rect(16, 60, 540, 34), "Encounter not implemented yet - prototype stops here.");
            GUI.Box(new Rect(WebRect.x, Screen.height - WebRect.yMax, WebRect.width, WebRect.height), "HOLD\nWEB");
            GUI.Box(new Rect(JumpRect.x, Screen.height - JumpRect.yMax, JumpRect.width, JumpRect.height), "JUMP");
            GUI.Label(new Rect(15, Screen.height - 48, 500, 36), "Left: move    Right: look    Space/E on keyboard");
        }
    }
}
