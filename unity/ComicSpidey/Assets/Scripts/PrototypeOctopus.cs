using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Separate test encounter; the supplied model has no skeleton or animation.
    [RequireComponent(typeof(CharacterController))]
    public sealed class PrototypeOctopus : MonoBehaviour
    {
        private readonly OctopusFightRules rules = new OctopusFightRules();
        private readonly List<Material> materials = new List<Material>();
        private PrototypeController player;
        private CharacterController motor;
        private GameObject visual, warning;
        private Vector3 start;
        private float verticalSpeed;
        public OctopusFightRules Rules => rules;
        private float SlamRadius => 2.8f + (rules.Phase - 1) * 0.3f;

        public void Initialize(PrototypeController target)
        {
            player = target;
            motor = GetComponent<CharacterController>();
            start = transform.position;
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            visual = new GameObject("StaticSuppliedOctopus");
            visual.transform.SetParent(transform, false);
            visual.transform.localPosition = Vector3.down;
            int loaded = 0;
            for (int i = 0; i < 3; i++)
            {
                var source = Resources.Load<GameObject>("DoctorOctopus/part_" + i);
                var texture = Resources.Load<Texture2D>("DoctorOctopus/part_" + i);
                if (source == null || texture == null || shader == null) continue;
                var part = Instantiate(source, visual.transform);
                var material = new Material(shader) { mainTexture = texture, color = Color.white };
                materials.Add(material);
                foreach (var renderer in part.GetComponentsInChildren<Renderer>()) renderer.sharedMaterial = material;
                loaded++;
            }
            if (loaded < 3)
            {
                Destroy(visual);
                visual = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                Destroy(visual.GetComponent<Collider>());
                visual.transform.SetParent(transform, false);
            }
            warning = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            warning.name = "SlamWarning";
            Destroy(warning.GetComponent<Collider>());
            if (shader != null)
            {
                var warningMaterial = new Material(shader) { color = new Color(1f, 0.17f, 0.05f) };
                materials.Add(warningMaterial);
                warning.GetComponent<Renderer>().sharedMaterial = warningMaterial;
            }
            warning.SetActive(false);
            rules.Reset(Time.time);
        }

        private void Update()
        {
            if (player == null || Time.timeScale == 0f || rules.State == OctopusState.Defeated) return;
            Vector3 delta = player.transform.position - transform.position;
            Vector3 flat = new Vector3(delta.x, 0, delta.z);
            bool close = flat.sqrMagnitude < SlamRadius * SlamRadius && Mathf.Abs(delta.y) < 3f;
            if (rules.Tick(Time.time, close) && close) player.ReceiveDamage(1);
            if (flat.sqrMagnitude > 0.01f)
                transform.rotation = Quaternion.Slerp(transform.rotation, Quaternion.LookRotation(flat), 7f * Time.deltaTime);
            if (motor.isGrounded && verticalSpeed < 0) verticalSpeed = -2f;
            verticalSpeed -= 20f * Time.deltaTime;
            Vector3 move = rules.State == OctopusState.Waiting && flat.magnitude > 2f ? flat.normalized * 2.2f : Vector3.zero;
            move.y = verticalSpeed;
            var flags = motor.Move(move * Time.deltaTime);
            if ((flags & CollisionFlags.Below) != 0 && verticalSpeed < 0) verticalSpeed = -2f;
            warning.SetActive(rules.State == OctopusState.Telegraph);
            warning.transform.position = transform.position + Vector3.down * 0.80f;
            warning.transform.localScale = new Vector3(SlamRadius * 2, 0.025f, SlamRadius * 2);
        }

        public void ReceiveHit()
        {
            if (!rules.TryHit()) return;
            if (rules.State == OctopusState.Defeated) warning.SetActive(false);
        }

        public void ResetFight()
        {
            rules.Reset(Time.time);
            motor.enabled = false;
            transform.position = start;
            motor.enabled = true;
            verticalSpeed = 0;
            warning.SetActive(false);
        }

        private void OnDestroy()
        {
            if (warning != null) Destroy(warning);
            foreach (var material in materials) if (material != null) Destroy(material);
        }
    }
}
