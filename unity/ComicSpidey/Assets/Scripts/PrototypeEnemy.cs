using UnityEngine;

namespace ComicSpidey
{
    // Placeholder adversary for the first test encounter, not a final NPC model.
    [RequireComponent(typeof(CharacterController))]
    public sealed class PrototypeEnemy : MonoBehaviour
    {
        private readonly CombatHealth health = new CombatHealth(3);
        private CharacterController motor;
        private PrototypeController player;
        private string enemyId;
        private System.Action<string> onDefeated;
        private readonly EnemyAttackTiming attack = new EnemyAttackTiming();
        private float verticalSpeed;
        private Renderer body;
        private float hitUntil, stunnedUntil, webbedUntil;
        private Material normalMaterial;
        private Material hitMaterial;
        private Material warningMaterial;
        private Material webMaterial;

        public bool Alive => !health.IsDefeated;

        public void Initialize(PrototypeController target, string id, Material normal, Material hit,
            Material warning, Material web, System.Action<string> defeated = null)
        {
            player = target;
            enemyId = id;
            onDefeated = defeated;
            motor = GetComponent<CharacterController>();
            normalMaterial = normal;
            hitMaterial = hit;
            warningMaterial = warning;
            webMaterial = web;
            var visual = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            visual.name = "TemporaryEnemyVisual";
            Destroy(visual.GetComponent<Collider>());
            visual.transform.SetParent(transform, false);
            body = visual.GetComponent<Renderer>();
            body.sharedMaterial = normalMaterial;
        }

        private void Update()
        {
            if (!Alive || player == null || Time.timeScale == 0f) return;
            Vector3 offset = player.transform.position - transform.position;
            Vector3 flat = new Vector3(offset.x, 0, offset.z);
            Vector3 motion = Vector3.zero;
            // Only chase nearby targets and don't pursue a player high above us.
            if (Time.time >= stunnedUntil && flat.sqrMagnitude < 16f * 16f && Mathf.Abs(offset.y) < 4f)
            {
                bool inRange = offset.sqrMagnitude < 2.2f * 2.2f;
                bool strike = attack.Tick(Time.time, inRange);
                if (!attack.WindingUp && flat.sqrMagnitude > 1.8f * 1.8f)
                    motion = flat.normalized * 3f;
                if (flat.sqrMagnitude > 0.001f)
                    transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(flat), 8f * Time.deltaTime);
                if (strike && CanReachPlayer())
                {
                    player.ReceiveDamage(1);
                    // The player's retry can remove this free-roam attacker.
                    if (!isActiveAndEnabled) return;
                }
            }
            else if (Time.time >= stunnedUntil)
                attack.Tick(Time.time, false); // Finish missed wind-ups even if the player fled.
            body.sharedMaterial = Time.time < webbedUntil ? webMaterial : Time.time < hitUntil ? hitMaterial : attack.WindingUp ? warningMaterial : normalMaterial;
            if (motor.isGrounded && verticalSpeed < 0) verticalSpeed = -2f;
            verticalSpeed -= 20f * Time.deltaTime;
            motion.y = verticalSpeed;
            var collision = motor.Move(motion * Time.deltaTime);
            if ((collision & CollisionFlags.Below) != 0 && verticalSpeed < 0) verticalSpeed = -2f;
        }

        private bool CanReachPlayer()
        {
            Vector3 direction = (player.transform.position - transform.position);
            float distance = direction.magnitude;
            if (distance < 0.001f) return false;
            if (!Physics.Raycast(transform.position + Vector3.up * 0.25f, direction / distance,
                out RaycastHit hit, distance, ~0, QueryTriggerInteraction.Ignore)) return false;
            return hit.transform == player.transform || hit.transform.IsChildOf(player.transform);
        }

        // A web shot interrupts a wind-up and immobilizes but does not deal damage.
        public void ReceiveWeb()
        {
            if (!Alive) return;
            webbedUntil = Time.time + (float)WebShooter.StunSeconds;
            stunnedUntil = Mathf.Max(stunnedUntil, webbedUntil);
            attack.Interrupt(stunnedUntil + 0.35f);
        }

        public void ReceiveHit(int damage, float stunSeconds)
        {
            if (!health.Damage(damage)) return;
            stunnedUntil = Mathf.Max(stunnedUntil, Time.time + Mathf.Max(0f, stunSeconds));
            attack.Interrupt(stunnedUntil + 0.35f);
            hitUntil = Mathf.Max(Time.time + 0.2f, stunnedUntil);
            if (!health.IsDefeated) return;
            // Report once, then hide immediately even though Destroy is delayed.
            gameObject.SetActive(false);
            if (onDefeated != null) onDefeated(enemyId);
            else player.EnemyDefeated(enemyId);
            Destroy(gameObject);
        }
    }
}
