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
        private int joystickFinger = -1, lookFinger = -1, webFinger = -1, attackFinger = -1;
        private float attackPressedAt, keyboardAttackPressedAt;
        private bool keyboardAttackHeld;
        private Vector2 joystickOrigin, moveInput;
        private bool jumpRequested, attackRequested, heavyAttackRequested, dodgeRequested, encounterSpawned;
        private readonly DodgeTiming dodge = new DodgeTiming();
        private readonly CombatCombo combo = new CombatCombo();
        private Vector3 dodgeDirection;
        private readonly CombatHealth health = new CombatHealth(6);
        private readonly List<PrototypeEnemy> enemies = new List<PrototypeEnemy>();
        private float invulnerableUntil, respawnNoticeUntil;
        private Material enemyMaterial, enemyHitMaterial, enemyWarningMaterial, enemyWebMaterial;
        private bool trackingMouse;
        private Vector3 lastMouse;
        private LineRenderer webLine, webShotLine;
        private readonly WebShooter webShooter = new WebShooter();
        private bool webShotRequested, rescueRequested;
        private float webShotVisibleUntil, webShotNoticeUntil;
        private string webShotNotice = "";
        private HeroVisual heroVisual;
        private PrototypeSettings settings;
        private PrototypeModeMenu modeMenu;
        private GameObject testMarker;
        private bool storyMode, bossMode;
        private PrototypeOctopus boss;
        private PrototypeCrime crime;
        private PrototypeCollectibles collectibles;
        private float climbBlockedUntil, webNoticeUntil, mantleBlockedTime, mantleStarted, nextMantleProbeAt;
        private bool climbing, mantling, mantleMovingForward;
        private Vector3 mantleLiftTarget, mantleForwardTarget, mantleInward;
        private StoryProgress story = new StoryProgress();
        private PrototypeCheckpoint checkpoint = new PrototypeCheckpoint();
        private const string CheckpointKey = "comicspidey.prototype.test-encounter.v1";
        public Transform CameraView => cameraTransform;

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
            webShotLine = gameObject.AddComponent<LineRenderer>();
            webShotLine.material = new Material(Resources.Load<Shader>("Hero/HeroLit"));
            webShotLine.material.color = Color.cyan;
            webShotLine.startColor = webShotLine.endColor = Color.cyan;
            webShotLine.startWidth = webShotLine.endWidth = 0.06f;
            webShotLine.positionCount = 2;
            webShotLine.enabled = false;
        }

        public void InitializeModeMenu(PrototypeModeMenu menu) { modeMenu = menu; }
        public void SetTestMarker(GameObject marker) { testMarker = marker; RefreshTestMarker(); }
        private void RefreshTestMarker()
        {
            if (testMarker != null) testMarker.SetActive(storyMode && story.Stage == 0);
        }

        public void StartMode(int mode)
        {
            storyMode = mode == 0;
            bossMode = mode == 2;
            if (storyMode) LoadTestCheckpoint();
            RefreshTestMarker();
            if (mode == 1)
            {
                crime = gameObject.AddComponent<PrototypeCrime>();
                crime.Initialize(this);
                collectibles = gameObject.AddComponent<PrototypeCollectibles>();
                collectibles.Initialize(transform, cameraTransform);
            }
            if (bossMode)
            {
                var actor = new GameObject("TestDoctorOctopus");
                actor.transform.position = new Vector3(0, 1, -12);
                var enemyMotor = actor.AddComponent<CharacterController>();
                enemyMotor.height = 2f;
                enemyMotor.radius = 0.55f;
                boss = actor.AddComponent<PrototypeOctopus>();
                boss.Initialize(this);
            }
        }

        // Use viewport-relative sizes so the touch targets scale on phones.
        private float ButtonSize => Mathf.Min(Screen.height * 0.20f, Screen.width * 0.12f);
        private float ButtonMargin => Mathf.Max(12f, Screen.height * 0.03f);
        private Rect JumpRect => new Rect(Screen.width - ButtonMargin - ButtonSize, ButtonMargin, ButtonSize, ButtonSize);
        private Rect WebRect => new Rect(JumpRect.x, JumpRect.yMax + ButtonMargin, ButtonSize, ButtonSize);
        private Rect AttackRect => new Rect(JumpRect.x, WebRect.yMax + ButtonMargin, ButtonSize, ButtonSize);
        private Rect WebShotRect => new Rect(JumpRect.x - ButtonSize - ButtonMargin, WebRect.y, ButtonSize, ButtonSize);
        private Rect RescueRect => new Rect(JumpRect.x - ButtonSize - ButtonMargin, AttackRect.y, ButtonSize, ButtonSize);
        private Rect DodgeRect => new Rect(JumpRect.x - ButtonSize - ButtonMargin, JumpRect.y, ButtonSize, ButtonSize);

        private void Update()
        {
            if (cameraTransform == null || (modeMenu != null && modeMenu.IsChoosing)) return;
            if (settings != null && settings.IsOpen)
            {
                ResetInput();
                return;
            }
            webShooter.Advance(Time.deltaTime);
            if (webShotLine.enabled && Time.time >= webShotVisibleUntil) webShotLine.enabled = false;
            HandleInput();
            if (mantling)
            {
                UpdateMantle();
                jumpRequested = attackRequested = heavyAttackRequested = dodgeRequested = webShotRequested = rescueRequested = false;
                return;
            }
            if (jumpRequested && webAttached)
            {
                // A web-jump releases the tether but preserves its horizontal momentum.
                webAttached = false;
                webLine.enabled = false;
                velocity.y = SwingMath.ReleaseVerticalSpeed(velocity.y);
                climbBlockedUntil = Time.time + 0.25f;
                jumpRequested = false;
            }
            var heading = Quaternion.Euler(0, yaw, 0);
            var desired = heading * new Vector3(moveInput.x, 0, moveInput.y);
            if (desired.sqrMagnitude > 1) desired.Normalize();
            if (dodgeRequested && dodge.TryStart(Time.time, motor.isGrounded, webAttached))
            {
                dodgeDirection = desired.sqrMagnitude > 0.01f ? desired.normalized : -(heading * Vector3.forward);
                jumpRequested = false;
            }
            dodgeRequested = false;
            bool dodging = dodge.IsActive(Time.time);
            climbing = false;
            if (!dodging && !webAttached && Time.time >= climbBlockedUntil && moveInput.y > 0.25f && desired.sqrMagnitude > 0.01f &&
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
                else if (TryStartMantle(wall))
                {
                    UpdateMantle();
                    jumpRequested = attackRequested = heavyAttackRequested = dodgeRequested = webShotRequested = rescueRequested = false;
                    return;
                }
                else velocity = Vector3.up * 4f - wall.normal * 0.6f;
            }
            else
            {
                if (motor.isGrounded && velocity.y < 0) velocity.y = -2f;
                if (!dodging && jumpRequested && motor.isGrounded) velocity.y = 8f;
                velocity.y -= 20f * Time.deltaTime;
                Vector3 horizontal = new Vector3(velocity.x, 0, velocity.z);
                // Steering adds acceleration instead of erasing tether momentum.
                if (dodging) horizontal = dodgeDirection * 11f;
                else if (webAttached)
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
            if (storyMode && story.Stage == 0 && story.Visit(transform.position.x, transform.position.y - 1f, transform.position.z))
            {
                RefreshTestMarker();
                checkpoint.StartEncounter();
                SaveTestCheckpoint();
                SpawnEncounter();
            }
            if (rescueRequested && crime != null) crime.TryRescue();
            rescueRequested = false;
            if (webShotRequested) TryWebShot();
            webShotRequested = false;
            if (attackRequested) TryAttack(heavyAttackRequested);
            attackRequested = false;
            heavyAttackRequested = false;
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

        private bool TryStartMantle(RaycastHit wall)
        {
            if (Time.time < nextMantleProbeAt) return false;
            nextMantleProbeAt = Time.time + 0.08f;
            // Probe a point beyond the wall, then look down for a tagged rooftop.
            // Only a nearby lip is eligible; higher roofs remain ordinary climb.
            float halfHeight = motor.height * 0.5f;
            Vector3 inward = -wall.normal;
            inward.y = 0;
            if (inward.sqrMagnitude < 0.5f) return false;
            inward.Normalize();
            Vector3 probe = transform.position + Vector3.up * (halfHeight + MantleMath.MaximumRise + 0.5f) +
                inward * (motor.radius + 0.3f);
            if (!Physics.Raycast(probe, Vector3.down, out RaycastHit top,
                halfHeight * 2f + MantleMath.MaximumRise + 1f, ~0, QueryTriggerInteraction.Ignore) ||
                top.collider != wall.collider || top.normal.y < 0.75f) return false;
            float feetY = transform.position.y + motor.center.y - halfHeight;
            if (!MantleMath.TryLift(feetY, top.point.y, out float lift)) return false;
            Vector3 liftTarget = transform.position + Vector3.up * lift;
            Vector3 forwardTarget = new Vector3(top.point.x, liftTarget.y, top.point.z);
            if (!CapsuleClearAt(liftTarget) || !CapsuleClearAt(forwardTarget)) return false;
            mantleLiftTarget = liftTarget;
            mantleForwardTarget = forwardTarget;
            mantleInward = inward;
            mantleMovingForward = false;
            mantleBlockedTime = 0;
            mantleStarted = Time.time;
            mantling = true;
            climbing = false;
            velocity = Vector3.zero;
            return true;
        }

        private bool CapsuleClearAt(Vector3 position)
        {
            float radius = Mathf.Max(0.05f, motor.radius - motor.skinWidth - 0.02f);
            float straightHalf = Mathf.Max(0, motor.height * 0.5f - radius);
            Vector3 center = position + motor.center;
            var hits = Physics.OverlapCapsule(center + Vector3.up * straightHalf, center - Vector3.up * straightHalf,
                radius, ~0, QueryTriggerInteraction.Ignore);
            foreach (var collider in hits)
                if (collider != null && collider != motor && !collider.transform.IsChildOf(transform)) return false;
            return true;
        }

        private void UpdateMantle()
        {
            if (jumpRequested)
            {
                CancelMantle();
                velocity = -mantleInward * 4f + Vector3.up * 5f;
                climbBlockedUntil = Time.time + 0.4f;
                return;
            }
            Vector3 target = mantleMovingForward ? mantleForwardTarget : mantleLiftTarget;
            Vector3 delta = target - transform.position;
            if (delta.magnitude < 0.05f)
            {
                if (!mantleMovingForward) { mantleMovingForward = true; mantleBlockedTime = 0; return; }
                CancelMantle();
                motor.Move(Vector3.down * 0.15f);
                climbBlockedUntil = Time.time + 0.2f;
                return;
            }
            Vector3 step = Vector3.ClampMagnitude(delta, 5f * Time.deltaTime);
            Vector3 before = transform.position;
            motor.Move(step);
            if ((transform.position - before).magnitude < step.magnitude * 0.1f) mantleBlockedTime += Time.deltaTime;
            else mantleBlockedTime = 0;
            // Never teleport through blockers, and abandon a jammed mantle.
            if (mantleBlockedTime > 0.3f || Time.time - mantleStarted > 2f) CancelMantle();
            if (heroVisual != null) heroVisual.UpdateMotion(false, false, step / Mathf.Max(Time.deltaTime, 0.001f));
        }

        private void CancelMantle()
        {
            mantling = false;
            mantleMovingForward = false;
            mantleBlockedTime = 0;
            velocity = Vector3.zero;
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
                if (Input.GetKeyDown(KeyCode.F)) { keyboardAttackHeld = true; keyboardAttackPressedAt = Time.time; }
                if (keyboardAttackHeld && Input.GetKeyUp(KeyCode.F))
                {
                    attackRequested = true;
                    heavyAttackRequested = Time.time - keyboardAttackPressedAt >= CombatCombo.HeavyHoldSeconds;
                    keyboardAttackHeld = false;
                }
                if (Input.GetKeyDown(KeyCode.LeftShift)) dodgeRequested = true;
                if (Input.GetKeyDown(KeyCode.Q)) webShotRequested = true;
                if (Input.GetKeyDown(KeyCode.R)) rescueRequested = true;
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
                    else if (DodgeRect.Contains(p)) dodgeRequested = true;
                    else if (crime != null && crime.RescueAvailable && RescueRect.Contains(p)) rescueRequested = true;
                    else if (!bossMode && WebShotRect.Contains(p)) webShotRequested = true;
                    else if (WebRect.Contains(p) && webFinger == -1) { webFinger = touch.fingerId; AttachWeb(); }
                    else if (AttackRect.Contains(p))
                    {
                        if (attackFinger == -1) { attackFinger = touch.fingerId; attackPressedAt = Time.time; }
                    }
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
                    if (touch.fingerId == attackFinger)
                    {
                        if (touch.phase == TouchPhase.Ended && AttackRect.Contains(p))
                        {
                            attackRequested = true;
                            heavyAttackRequested = Time.time - attackPressedAt >= CombatCombo.HeavyHoldSeconds;
                        }
                        attackFinger = -1;
                    }
                }
            }
        }

        private void EnsureEnemyMaterials()
        {
            if (enemyMaterial != null && enemyHitMaterial != null && enemyWarningMaterial != null && enemyWebMaterial != null) return;
            Shader shader = Resources.Load<Shader>("Hero/HeroLit");
            enemyMaterial = new Material(shader) { color = new Color(0.44f, 0.12f, 0.22f) };
            enemyHitMaterial = new Material(shader) { color = new Color(1f, 0.8f, 0.25f) };
            enemyWarningMaterial = new Material(shader) { color = new Color(1f, 0.25f, 0.05f) };
            enemyWebMaterial = new Material(shader) { color = new Color(0.25f, 0.85f, 1f) };
        }

        private PrototypeEnemy CreateEnemy(string id, Vector3 position, System.Action<string> onDefeated = null)
        {
            EnsureEnemyMaterials();
            enemies.RemoveAll(enemy => enemy == null);
            var enemy = new GameObject(id);
            enemy.transform.position = position;
            var enemyMotor = enemy.AddComponent<CharacterController>();
            enemyMotor.height = 2f;
            enemyMotor.radius = 0.45f;
            var actor = enemy.AddComponent<PrototypeEnemy>();
            actor.Initialize(this, id, enemyMaterial, enemyHitMaterial, enemyWarningMaterial, enemyWebMaterial, onDefeated);
            enemies.Add(actor);
            return actor;
        }

        private void SpawnEncounter()
        {
            if (encounterSpawned) return;
            encounterSpawned = true;
            for (int i = 0; i < 2; i++)
            {
                if (checkpoint.IsDefeated(i)) continue;
                CreateEnemy("test-attacker-" + i, new Vector3(i == 0 ? -4f : 4f, 1f, -48f));
            }
        }

        public PrototypeEnemy SpawnCrimeEnemy(string id, Vector3 position, System.Action<string> onDefeated)
        {
            return CreateEnemy(id, position, onDefeated);
        }

        public void RemoveCrimeEnemy(PrototypeEnemy actor)
        {
            if (actor == null) return;
            enemies.Remove(actor);
            actor.gameObject.SetActive(false);
            Destroy(actor.gameObject);
        }

        // Camera-facing target assistance only chooses visible active enemies.
        // No projectile, boss effects, persistent upgrades or damage in this test.
        private void TryWebShot()
        {
            bool activeCrime = crime != null && crime.EncounterActive;
            if (dodge.IsActive(Time.time) || (!activeCrime && (!storyMode || story.Stage != 1))) return;
            if (!webShooter.TryFire(Time.time))
            {
                webShotNotice = webShooter.Charges == 0 ? "WEB RECHARGING" : "WEB COOLDOWN";
                webShotNoticeUntil = Time.time + 0.8f;
                return;
            }
            Vector3 origin = transform.position + Vector3.up * 0.25f;
            Vector3 view = Quaternion.Euler(0, yaw, 0) * Vector3.forward;
            PrototypeEnemy target = null;
            float best = float.MaxValue;
            foreach (var enemy in enemies)
            {
                if (enemy == null || !enemy.Alive) continue;
                Vector3 offset = enemy.transform.position - transform.position;
                if (!WebAimMath.TryScore(view.x, view.z, offset.x, offset.y, offset.z, out float score) ||
                    !CanReachAttack(enemy.transform, WebAimMath.Range)) continue;
                if (score < best) { best = score; target = enemy; }
            }
            Vector3 end = target != null ? target.transform.position + Vector3.up * 0.25f : origin + view * 5f;
            // A missed beam should stop at a wall, too; it is feedback, not a projectile.
            if (target == null && Physics.Raycast(origin, view, out RaycastHit hit, 5f, ~0, QueryTriggerInteraction.Ignore)) end = hit.point;
            webShotLine.SetPosition(0, origin);
            webShotLine.SetPosition(1, end);
            webShotLine.enabled = true;
            webShotVisibleUntil = Time.time + 0.12f;
            webShotNotice = target != null ? "WEBBED" : "WEB MISSED";
            webShotNoticeUntil = Time.time + 0.8f;
            if (target != null) target.ReceiveWeb();
        }

        private void TryAttack(bool heavy)
        {
            bool activeCrime = crime != null && crime.EncounterActive;
            if (dodge.IsActive(Time.time) || (!bossMode && !activeCrime && (!storyMode || story.Stage != 1))) return;
            if (bossMode)
            {
                bool connected = boss != null && boss.Rules.State == OctopusState.Recovery &&
                    CanReachAttack(boss.transform, 3f);
                if (combo.TryAttack(Time.time, heavy, connected, out int damage, out _) && connected)
                    boss.ReceiveHit(damage);
                return;
            }
            PrototypeEnemy target = null;
            float bestSquared = 2.8f * 2.8f;
            foreach (var enemy in enemies)
            {
                if (enemy == null || !enemy.Alive) continue;
                float distanceSquared = (enemy.transform.position - transform.position).sqrMagnitude;
                if (distanceSquared < bestSquared && CanReachAttack(enemy.transform, 2.8f))
                { bestSquared = distanceSquared; target = enemy; }
            }
            if (combo.TryAttack(Time.time, heavy, target != null, out int hitDamage, out double stun) && target != null)
                target.ReceiveHit(hitDamage, (float)stun);
        }

        // A nearby actor behind a wall or vehicle cannot be hit through it.
        private bool CanReachAttack(Transform target, float range)
        {
            Vector3 origin = transform.position + Vector3.up * 0.25f;
            Vector3 destination = target.position + Vector3.up * 0.25f;
            Vector3 direction = destination - origin;
            float distance = direction.magnitude;
            if (distance < 0.001f || distance >= range) return false;
            if (!Physics.Raycast(origin, direction / distance, out RaycastHit hit, distance,
                ~0, QueryTriggerInteraction.Ignore)) return false;
            return hit.transform == target || hit.transform.IsChildOf(target);
        }

        public void EnemyDefeated(string enemyId)
        {
            int index = enemyId == "test-attacker-0" ? 0 : enemyId == "test-attacker-1" ? 1 : -1;
            if (story.Stage != 1 || !checkpoint.MarkDefeated(index)) return;
            story.EnemyDefeated(enemyId);
            SaveTestCheckpoint();
        }

        private void LoadTestCheckpoint()
        {
            if (!PrototypeCheckpoint.TryDecode(PlayerPrefs.GetString(CheckpointKey, ""), out var saved)) return;
            checkpoint = saved;
            if (checkpoint.Phase == 0) return;
            // Rebuild runtime objective state from a validated, tiny checkpoint.
            story.Visit(0, 0, -44);
            for (int i = 0; i < 2; i++)
                if (checkpoint.IsDefeated(i)) story.EnemyDefeated("test-attacker-" + i);
            motor.enabled = false;
            transform.position = new Vector3(0, 1, -35);
            motor.enabled = true;
            if (checkpoint.Phase == 1) SpawnEncounter();
        }

        private void SaveTestCheckpoint()
        {
            PlayerPrefs.SetString(CheckpointKey, checkpoint.Encode());
            PlayerPrefs.Save();
        }

        // Settings exposes this as an explicitly confirmed reset of the test
        // checkpoint only. It does not touch graphics options or other game data.
        public void ResetTestProgress()
        {
            if (crime != null) crime.PlayerDefeated();
            foreach (var enemy in enemies)
            {
                if (enemy == null) continue;
                enemy.gameObject.SetActive(false);
                Destroy(enemy.gameObject);
            }
            enemies.Clear();
            if (enemyMaterial != null) Destroy(enemyMaterial);
            if (enemyHitMaterial != null) Destroy(enemyHitMaterial);
            if (enemyWarningMaterial != null) Destroy(enemyWarningMaterial);
            if (enemyWebMaterial != null) Destroy(enemyWebMaterial);
            enemyMaterial = enemyHitMaterial = enemyWarningMaterial = enemyWebMaterial = null;
            encounterSpawned = false;
            checkpoint = new PrototypeCheckpoint();
            story = new StoryProgress();
            RefreshTestMarker();
            health.Restore();
            motor.enabled = false;
            transform.position = new Vector3(0, 1, 0);
            motor.enabled = true;
            velocity = Vector3.zero;
            yaw = 180f;
            pitch = 18f;
            ResetInput();
            webLine.enabled = false;
            invulnerableUntil = 0f;
            dodge.Reset();
            combo.Reset();
            webShooter.Reset();
            PlayerPrefs.DeleteKey(CheckpointKey);
            PlayerPrefs.Save();
        }

        // Separate from the story checkpoint, graphics and all future campaign saves.
        public void ResetCrimeProgress()
        {
            if (crime != null) crime.ResetCount();
            else PrototypeCrime.ClearSavedProgress();
        }

        // Test collectibles have a separate key from crimes and the story test.
        public void ResetCollectibleProgress()
        {
            if (collectibles != null) collectibles.ResetProgress();
            else PrototypeCollectibles.ClearSavedProgress();
        }

        public void ReceiveDamage(int amount)
        {
            if (Time.time < invulnerableUntil || dodge.IsProtected(Time.time) || !health.Damage(amount)) return;
            invulnerableUntil = Time.time + 0.65f;
            if (!health.IsDefeated) return;
            // A simple retry for this prototype: enemies already defeated stay
            // defeated. This is not the game's checkpoint/save implementation.
            motor.enabled = false;
            transform.position = storyMode ? new Vector3(0, 1, -35) : new Vector3(0, 1, 0);
            motor.enabled = true;
            velocity = Vector3.zero;
            webAttached = false;
            if (mantling) CancelMantle();
            dodge.Reset();
            combo.Reset();
            webShooter.Reset();
            if (webShotLine != null) webShotLine.enabled = false;
            health.Restore();
            if (bossMode && boss != null) boss.ResetFight();
            if (crime != null) crime.PlayerDefeated();
            invulnerableUntil = Time.time + 2f;
            respawnNoticeUntil = Time.time + 3f;
        }

        private void OnDestroy()
        {
            if (enemyMaterial != null) Destroy(enemyMaterial);
            if (enemyHitMaterial != null) Destroy(enemyHitMaterial);
            if (enemyWarningMaterial != null) Destroy(enemyWarningMaterial);
            if (enemyWebMaterial != null) Destroy(enemyWebMaterial);
            if (webLine != null && webLine.material != null) Destroy(webLine.material);
            if (webShotLine != null && webShotLine.material != null) Destroy(webShotLine.material);
        }

        private void LimitOutwardVelocity(Vector3 rope)
        {
            SwingMath.LimitOutwardVelocity(rope.x, rope.y, rope.z, velocity.x, velocity.y, velocity.z,
                out float x, out float y, out float z);
            velocity = new Vector3(x, y, z);
        }

        private void AttachWeb()
        {
            if (dodge.IsActive(Time.time) || mantling) return;
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
            else webNoticeUntil = Time.time + 1.2f;
        }

        private void OnApplicationFocus(bool focus)
        {
            if (!focus) ResetInput();
        }

        private void ResetInput()
        {
            joystickFinger = lookFinger = webFinger = attackFinger = -1;
            moveInput = Vector2.zero;
            webAttached = false;
            jumpRequested = false;
            attackRequested = false;
            heavyAttackRequested = false;
            keyboardAttackHeld = false;
            dodgeRequested = false;
            webShotRequested = rescueRequested = false;
            if (webShotLine != null) webShotLine.enabled = false;
            if (webLine != null) webLine.enabled = false;
            dodge.Cancel();
            combo.CancelChain();
            if (mantling) CancelMantle();
            trackingMouse = false;
        }

        private void OnGUI()
        {
            if (modeMenu != null && modeMenu.IsChoosing) return;
            float unit = Mathf.Min(Screen.width, Screen.height);
            int font = Mathf.Max(16, Mathf.RoundToInt(unit * 0.035f));
            var panel = new GUIStyle(GUI.skin.box) { fontSize = font, alignment = TextAnchor.MiddleCenter, wordWrap = true };
            var label = new GUIStyle(GUI.skin.label) { fontSize = font, wordWrap = true };
            string objective = bossMode ? "Doctor Octopus — test fight" : crime != null ? crime.Status : !storyMode ? "Free roam — test city" : story.Stage >= 2 ? "Test encounter complete" : story.Current.Title;
            if (storyMode && story.Stage == 0)
            {
                Vector3 offset = new Vector3(story.Current.X, 0, story.Current.Z) - transform.position;
                Transform view = cameraTransform != null ? cameraTransform : transform;
                objective += " — " + CompassMath.Direction(view.forward.x, view.forward.z, offset.x, offset.y, offset.z) +
                    " " + Mathf.RoundToInt(offset.magnitude) + "m";
            }
            GUI.Box(new Rect(ButtonMargin, ButtonMargin, Screen.width * 0.45f, unit * 0.09f), "PROTOTYPE - " + objective, panel);
            string status = "Health " + health.Current + "/" + health.Maximum;
            if (storyMode && story.Stage == 1) status += "   Attackers " + story.DefeatedCount + "/2";
            if (bossMode && boss != null)
            {
                var fight = boss.Rules;
                status += "   OCK " + fight.Health + "/" + OctopusFightRules.MaximumHealth + "  PHASE " + fight.Phase;
                status += fight.State == OctopusState.Telegraph ? "  DODGE!" :
                    fight.State == OctopusState.Recovery ? "  ATTACK!" :
                    fight.State == OctopusState.Defeated ? "  TEST COMPLETE" : "";
            }
            if (!bossMode) status += "   WEB " + webShooter.Charges + "/" + WebShooter.Capacity;
            if (Time.time < webShotNoticeUntil) status += "   " + webShotNotice;
            if (Time.time < respawnNoticeUntil) status += "   RETRY";
            if (climbing) status += "   CLIMB";
            if (mantling) status += "   MANTLE";
            if (!webAttached && Time.time < webNoticeUntil) status += "   NO WEB SURFACE";
            if (dodge.IsActive(Time.time)) status += "   DODGE";
            GUI.Label(new Rect(ButtonMargin, unit * 0.13f, Screen.width * 0.55f, unit * 0.1f), status, label);
            if (collectibles != null)
                GUI.Label(new Rect(ButtonMargin, unit * 0.23f, Screen.width * 0.58f, unit * 0.1f), collectibles.Status, label);
            GUI.Box(new Rect(WebRect.x, Screen.height - WebRect.yMax, WebRect.width, WebRect.height), "HOLD\nWEB", panel);
            GUI.Box(new Rect(JumpRect.x, Screen.height - JumpRect.yMax, JumpRect.width, JumpRect.height), "JUMP", panel);
            GUI.Box(new Rect(AttackRect.x, Screen.height - AttackRect.yMax, AttackRect.width, AttackRect.height), "ATTACK\nTAP/HOLD", panel);
            GUI.Box(new Rect(DodgeRect.x, Screen.height - DodgeRect.yMax, DodgeRect.width, DodgeRect.height), "DODGE", panel);
            if (!bossMode) GUI.Box(new Rect(WebShotRect.x, Screen.height - WebShotRect.yMax, WebShotRect.width, WebShotRect.height), "WEB\nSHOT", panel);
            if (crime != null && crime.RescueAvailable)
                GUI.Box(new Rect(RescueRect.x, Screen.height - RescueRect.yMax, RescueRect.width, RescueRect.height), "RESCUE", panel);
            if (joystickFinger == -1)
                GUI.Label(new Rect(ButtonMargin, Screen.height - unit * 0.14f, Screen.width * 0.4f, unit * 0.1f), "Drag left to move", label);
        }
    }
}
