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
        private Vector3 webPoint;
        private bool webAttached;
        private float ropeLength;
        private float yaw = 180f;
        private float pitch = 18f;
        private int joystickFinger = -1, lookFinger = -1, webFinger = -1;
        private Vector2 joystickOrigin, moveInput;
        private bool jumpRequested, attackRequested, encounterSpawned;
        private readonly CombatHealth health = new CombatHealth(6);
        private readonly List<PrototypeEnemy> enemies = new List<PrototypeEnemy>();
        private float nextAttack, invulnerableUntil, respawnNoticeUntil;
        private Material enemyMaterial, enemyHitMaterial;
        private bool trackingMouse;
        private Vector3 lastMouse;
        private LineRenderer webLine;
        private HeroVisual heroVisual;
        private PrototypeSettings settings;
        private float climbBlockedUntil;
        private bool climbing;
        private readonly StoryProgress story = new StoryProgress();

        public void Initialize(Transform cameraView, List<Transform> webAnchors)
        {
            motor = GetComponent<CharacterController>();
            heroVisual = GetComponent<HeroVisual>();
            settings = GetComponent<PrototypeSettings>();
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
        private float ButtonSize => Mathf.Min(Screen.height * 0.20f, Screen.width * 0.12f);
        private float ButtonMargin => Mathf.Max(12f, Screen.height * 0.03f);
        private Rect JumpRect => new Rect(Screen.width - ButtonMargin - ButtonSize, ButtonMargin, ButtonSize, ButtonSize);
        private Rect WebRect => new Rect(JumpRect.x, JumpRect.yMax + ButtonMargin, ButtonSize, ButtonSize);
        private Rect AttackRect => new Rect(JumpRect.x, WebRect.yMax + ButtonMargin, ButtonSize, ButtonSize);

        private void Update()
        {
            if (cameraTransform == null) return;
            if (settings != null && settings.IsOpen)
            {
                ResetInput();
                return;
            }
            HandleInput();
            var heading = Quaternion.Euler(0, yaw, 0);
            var desired = heading * new Vector3(moveInput.x, 0, moveInput.y);
            if (desired.sqrMagnitude > 1) desired.Normalize();
            climbing = false;
            if (!webAttached && Time.time >= climbBlockedUntil && moveInput.y > 0.25f && desired.sqrMagnitude > 0.01f &&
                Physics.Raycast(transform.position + Vector3.up * 0.3f, desired.normalized, out RaycastHit wall,
                    motor.radius + 0.4f, ~0, QueryTriggerInteraction.Ignore) &&
                wall.collider.GetComponent<ClimbableSurface>() != null && Mathf.Abs(wall.normal.y) < 0.2f &&
                Vector3.Dot(desired, wall.normal) < -0.15f)
            {
                climbing = true;
                if (jumpRequested)
                {
                    // A wall jump disengages briefly so input can't reattach instantly.
                    velocity = wall.normal * 6f + Vector3.up * 7f;
                    climbing = false;
                    climbBlockedUntil = Time.time + 0.4f;
                }
                else velocity = Vector3.up * 4f - wall.normal * 0.6f;
            }
            else
            {
                if (motor.isGrounded && velocity.y < 0) velocity.y = -2f;
                if (jumpRequested && motor.isGrounded) velocity.y = 8f;
                velocity.y -= 20f * Time.deltaTime;
                Vector3 horizontal = new Vector3(velocity.x, 0, velocity.z);
                // Steering adds acceleration instead of erasing tether momentum.
                if (webAttached)
                {
                    horizontal += desired * (5f * Time.deltaTime);
                    horizontal = Vector3.ClampMagnitude(horizontal, 24f);
                }
                else if (motor.isGrounded || desired.sqrMagnitude > 0.001f)
                    horizontal = Vector3.MoveTowards(horizontal, desired * 7f, (motor.isGrounded ? 28f : 4f) * Time.deltaTime);
                velocity.x = horizontal.x;
                velocity.z = horizontal.z;
            }
            jumpRequested = false;

            // An intentionally simple tether prototype, not a finished swing system.
            if (webAttached)
            {
                Vector3 rope = transform.position - webPoint;
                if (rope.magnitude >= ropeLength - 0.05f)
                    LimitOutwardVelocity(rope);
            }
            var collisions = motor.Move(velocity * Time.deltaTime);
            if ((collisions & CollisionFlags.Above) != 0 && velocity.y > 0) velocity.y = 0;
            if ((collisions & CollisionFlags.Below) != 0 && velocity.y < 0) velocity.y = -2f;
            // Stop after the first experimental encounter; the following legacy
            // objectives are outside this small test world and are not the campaign.
            if (story.Stage == 0 && story.Visit(transform.position.x, transform.position.y - 1f, transform.position.z))
                SpawnEncounter();
            if (attackRequested) TryAttack();
            attackRequested = false;
            if (webAttached)
            {
                Vector3 rope = transform.position - webPoint;
                if (rope.magnitude > ropeLength)
                {
                    motor.Move(-rope.normalized * (rope.magnitude - ropeLength));
                    LimitOutwardVelocity(transform.position - webPoint);
                }
                webLine.enabled = true;
                webLine.SetPosition(0, transform.position + Vector3.up * 0.5f);
                webLine.SetPosition(1, webPoint);
            }
            else webLine.enabled = false;
            if (heroVisual != null) heroVisual.UpdateMotion(motor.isGrounded, webAttached, velocity);
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
                if (Input.GetKeyDown(KeyCode.F)) attackRequested = true;
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
                if (Input.GetKeyUp(KeyCode.E)) webAttached = false;
            }
            foreach (Touch touch in Input.touches)
            {
                Vector2 p = touch.position; // Touch positions have a bottom-left origin.
                if (touch.phase == TouchPhase.Began)
                {
                    if (settings != null && settings.BlocksTouch(p)) continue;
                    if (JumpRect.Contains(p)) jumpRequested = true;
                    else if (WebRect.Contains(p) && webFinger == -1) { webFinger = touch.fingerId; AttachWeb(); }
                    else if (AttackRect.Contains(p)) attackRequested = true;
                    else if (p.x < Screen.width * 0.45f && joystickFinger == -1) { joystickFinger = touch.fingerId; joystickOrigin = p; moveInput = Vector2.zero; }
                    else if (lookFinger == -1) lookFinger = touch.fingerId;
                }
                if (touch.fingerId == joystickFinger)
                    moveInput = Vector2.ClampMagnitude((p - joystickOrigin) / (Mathf.Min(Screen.width, Screen.height) * 0.12f), 1f);
                if (touch.fingerId == lookFinger && touch.phase == TouchPhase.Moved)
                {
                    yaw += touch.deltaPosition.x * 0.16f;
                    pitch = Mathf.Clamp(pitch - touch.deltaPosition.y * 0.16f, -25, 65);
                }
                if (touch.phase == TouchPhase.Ended || touch.phase == TouchPhase.Canceled)
                {
                    if (touch.fingerId == joystickFinger) { joystickFinger = -1; moveInput = Vector2.zero; }
                    if (touch.fingerId == lookFinger) lookFinger = -1;
                    if (touch.fingerId == webFinger) { webFinger = -1; webAttached = false; }
                }
            }
        }

        private void SpawnEncounter()
        {
            if (encounterSpawned) return;
            encounterSpawned = true;
            Shader shader = Resources.Load<Shader>("Hero/HeroLit");
            enemyMaterial = new Material(shader) { color = new Color(0.44f, 0.12f, 0.22f) };
            enemyHitMaterial = new Material(shader) { color = new Color(1f, 0.8f, 0.25f) };
            for (int i = 0; i < 2; i++)
            {
                var enemy = new GameObject("TestAttacker" + i);
                enemy.transform.position = new Vector3(i == 0 ? -4f : 4f, 1f, -48f);
                var enemyMotor = enemy.AddComponent<CharacterController>();
                enemyMotor.height = 2f;
                enemyMotor.radius = 0.45f;
                var actor = enemy.AddComponent<PrototypeEnemy>();
                actor.Initialize(this, "test-attacker-" + i, enemyMaterial, enemyHitMaterial);
                enemies.Add(actor);
            }
        }

        private void TryAttack()
        {
            if (story.Stage != 1 || Time.time < nextAttack) return;
            nextAttack = Time.time + 0.45f;
            PrototypeEnemy target = null;
            float bestSquared = 2.8f * 2.8f;
            foreach (var enemy in enemies)
            {
                if (enemy == null || !enemy.Alive) continue;
                float distanceSquared = (enemy.transform.position - transform.position).sqrMagnitude;
                if (distanceSquared < bestSquared) { bestSquared = distanceSquared; target = enemy; }
            }
            if (target != null) target.ReceiveHit();
        }

        public void EnemyDefeated(string enemyId)
        {
            if (story.Stage == 1) story.EnemyDefeated(enemyId);
        }

        public void ReceiveDamage(int amount)
        {
            if (Time.time < invulnerableUntil || !health.Damage(amount)) return;
            invulnerableUntil = Time.time + 0.65f;
            if (!health.IsDefeated) return;
            // A simple retry for this prototype: enemies already defeated stay
            // defeated. This is not the game's checkpoint/save implementation.
            motor.enabled = false;
            transform.position = new Vector3(0, 1, -35);
            motor.enabled = true;
            velocity = Vector3.zero;
            webAttached = false;
            health.Restore();
            invulnerableUntil = Time.time + 2f;
            respawnNoticeUntil = Time.time + 3f;
        }

        private void OnDestroy()
        {
            if (enemyMaterial != null) Destroy(enemyMaterial);
            if (enemyHitMaterial != null) Destroy(enemyHitMaterial);
            if (webLine != null && webLine.material != null) Destroy(webLine.material);
        }

        private void LimitOutwardVelocity(Vector3 rope)
        {
            SwingMath.LimitOutwardVelocity(rope.x, rope.y, rope.z, velocity.x, velocity.y, velocity.z,
                out float x, out float y, out float z);
            velocity = new Vector3(x, y, z);
        }

        private void AttachWeb()
        {
            // Try nearby building rooftops, but attach only where an unobstructed
            // ray actually hits a tagged building. Do not tether to empty sky.
            webAttached = false;
            float bestScore = float.MaxValue;
            Vector3 origin = transform.position + Vector3.up * 0.5f;
            Vector3 viewForward = Quaternion.Euler(0, yaw, 0) * Vector3.forward;
            foreach (Transform anchor in anchors)
            {
                if (anchor == null) continue;
                Vector3 target = anchor.position - Vector3.up;
                Vector3 direction = target - origin;
                float distance = direction.magnitude;
                if (distance < 0.01f || distance > 45f) continue;
                if (!Physics.Raycast(origin, direction / distance, out RaycastHit hit,
                    distance + 0.2f, ~0, QueryTriggerInteraction.Ignore) ||
                    hit.collider.GetComponent<ClimbableSurface>() == null || hit.point.y < origin.y + 0.5f) continue;
                Vector3 flat = new Vector3(direction.x, 0, direction.z).normalized;
                float score = distance - Vector3.Dot(viewForward, flat) * 8f;
                if (score >= bestScore) continue;
                bestScore = score;
                webPoint = hit.point;
                webAttached = true;
            }
            if (webAttached) ropeLength = Vector3.Distance(transform.position, webPoint);
        }

        private void OnApplicationFocus(bool focus)
        {
            if (!focus) ResetInput();
        }

        private void ResetInput()
        {
            joystickFinger = lookFinger = webFinger = -1;
            moveInput = Vector2.zero;
            webAttached = false;
            jumpRequested = false;
            attackRequested = false;
            trackingMouse = false;
        }

        private void OnGUI()
        {
            float unit = Mathf.Min(Screen.width, Screen.height);
            int font = Mathf.Max(16, Mathf.RoundToInt(unit * 0.035f));
            var panel = new GUIStyle(GUI.skin.box) { fontSize = font, alignment = TextAnchor.MiddleCenter, wordWrap = true };
            var label = new GUIStyle(GUI.skin.label) { fontSize = font, wordWrap = true };
            string objective = story.Stage >= 2 ? "Test encounter complete" : story.Current.Title;
            GUI.Box(new Rect(ButtonMargin, ButtonMargin, Screen.width * 0.45f, unit * 0.09f), "PROTOTYPE - " + objective, panel);
            string status = "Health " + health.Current + "/" + health.Maximum;
            if (story.Stage == 1) status += "   Attackers " + story.DefeatedCount + "/2";
            if (Time.time < respawnNoticeUntil) status += "   RETRY";
            if (climbing) status += "   CLIMB";
            GUI.Label(new Rect(ButtonMargin, unit * 0.13f, Screen.width * 0.55f, unit * 0.1f), status, label);
            GUI.Box(new Rect(WebRect.x, Screen.height - WebRect.yMax, WebRect.width, WebRect.height), "HOLD\nWEB", panel);
            GUI.Box(new Rect(JumpRect.x, Screen.height - JumpRect.yMax, JumpRect.width, JumpRect.height), "JUMP", panel);
            GUI.Box(new Rect(AttackRect.x, Screen.height - AttackRect.yMax, AttackRect.width, AttackRect.height), "ATTACK", panel);
            if (joystickFinger == -1)
                GUI.Label(new Rect(ButtonMargin, Screen.height - unit * 0.14f, Screen.width * 0.4f, unit * 0.1f), "Drag left to move", label);
        }
    }
}
