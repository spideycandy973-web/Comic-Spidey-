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
        private float nextAttack;
        private float verticalSpeed;
        private Renderer body;
        private float hitUntil;
        private Material normalMaterial;
        private Material hitMaterial;

        public bool Alive => !health.IsDefeated;

        public void Initialize(PrototypeController target, string id, Material normal, Material hit)
        {
            player = target;
            enemyId = id;
            motor = GetComponent<CharacterController>();
            normalMaterial = normal;
            hitMaterial = hit;
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
            body.sharedMaterial = Time.time < hitUntil ? hitMaterial : normalMaterial;
            Vector3 offset = player.transform.position - transform.position;
            Vector3 flat = new Vector3(offset.x, 0, offset.z);
            Vector3 motion = Vector3.zero;
            // Only chase nearby targets and don't pursue a player high above us.
            if (flat.sqrMagnitude < 16f * 16f && Mathf.Abs(offset.y) < 4f)
            {
                if (flat.sqrMagnitude > 1.8f * 1.8f)
                    motion = flat.normalized * 3f;
                if (flat.sqrMagnitude > 0.001f)
                    transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(flat), 8f * Time.deltaTime);
                if (offset.sqrMagnitude < 2.2f * 2.2f && Time.time >= nextAttack)
                {
                    nextAttack = Time.time + 1.5f;
                    player.ReceiveDamage(1);
                }
            }
            if (motor.isGrounded && verticalSpeed < 0) verticalSpeed = -2f;
            verticalSpeed -= 20f * Time.deltaTime;
            motion.y = verticalSpeed;
            var collision = motor.Move(motion * Time.deltaTime);
            if ((collision & CollisionFlags.Below) != 0 && verticalSpeed < 0) verticalSpeed = -2f;
        }

        public void ReceiveHit()
        {
            if (!health.Damage(1)) return;
            hitUntil = Time.time + 0.2f;
            if (!health.IsDefeated) return;
            // Report once, then hide immediately even though Destroy is delayed.
            gameObject.SetActive(false);
            player.EnemyDefeated(enemyId);
            Destroy(gameObject);
        }
    }
}
