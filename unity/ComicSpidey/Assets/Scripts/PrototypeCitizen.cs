using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Small pedestrian patrol prototype. This is not final civilian AI.
    [RequireComponent(typeof(CharacterController))]
    public sealed class PrototypeCitizen : MonoBehaviour
    {
        private CharacterController motor;
        private Transform visual;
        private float firstZ, lastZ, direction, verticalSpeed, blockedTime;
        private static readonly Dictionary<Material, Material> ToonMaterials = new Dictionary<Material, Material>();

        public void Initialize(string resource, float minZ, float maxZ, float initialDirection)
        {
            motor = GetComponent<CharacterController>();
            firstZ = minZ;
            lastZ = maxZ;
            direction = initialDirection >= 0 ? 1f : -1f;
            var source = Resources.Load<GameObject>("Citizens/" + resource);
            GameObject model = source != null ? Instantiate(source, transform) : null;
            Renderer[] renderers = model != null ? model.GetComponentsInChildren<Renderer>(true) : new Renderer[0];
            if (renderers.Length == 0)
            {
                if (model != null) Destroy(model);
                model = GameObject.CreatePrimitive(PrimitiveType.Capsule);
                Destroy(model.GetComponent<Collider>());
                model.transform.SetParent(transform, false);
                model.transform.localPosition = Vector3.up * 0.9f;
                model.transform.localScale = new Vector3(0.6f, 0.9f, 0.6f);
                renderers = model.GetComponentsInChildren<Renderer>();
            }
            else
            {
                // Normalize imported units and place the visual's feet on the pavement.
                var bounds = renderers[0].bounds;
                for (int i = 1; i < renderers.Length; i++) bounds.Encapsulate(renderers[i].bounds);
                if (bounds.size.y > 0.001f)
                {
                    model.transform.localScale *= 1.8f / bounds.size.y;
                    bounds = renderers[0].bounds;
                    for (int i = 1; i < renderers.Length; i++) bounds.Encapsulate(renderers[i].bounds);
                    model.transform.position += Vector3.up * (transform.position.y - bounds.min.y);
                }
                // Legacy clips are imported separately from the FBX. Their
                // behaviour/rig still needs actual Unity and Android validation.
                var animationPlayer = model.GetComponent<Animation>();
                if (animationPlayer == null) animationPlayer = model.AddComponent<Animation>();
                animationPlayer.playAutomatically = false;
                AnimationClip walk = null;
                foreach (var clip in Resources.LoadAll<AnimationClip>("Citizens/" + resource))
                    if (clip != null && clip.legacy && !clip.name.StartsWith("__preview__") &&
                        clip.length > 0.1f && (walk == null || clip.length > walk.length)) walk = clip;
                if (walk != null)
                {
                    animationPlayer.AddClip(walk, "walk");
                    animationPlayer["walk"].wrapMode = WrapMode.Loop;
                    animationPlayer.Play("walk");
                }
            }
            visual = model.transform;
            foreach (var renderer in renderers)
            {
                var materials = renderer.sharedMaterials;
                for (int i = 0; i < materials.Length; i++)
                {
                    Material original = materials[i];
                    if (original == null) continue;
                    if (!ToonMaterials.TryGetValue(original, out Material comic) || comic == null)
                    {
                        var shader = Resources.Load<Shader>("Hero/HeroLit");
                        if (shader == null) continue;
                        comic = new Material(shader);
                        if (original.HasProperty("_Color")) comic.color = original.color;
                        if (original.HasProperty("_MainTex")) comic.mainTexture = original.mainTexture;
                        ToonMaterials[original] = comic;
                    }
                    materials[i] = comic;
                }
                renderer.sharedMaterials = materials;
                if (renderer is SkinnedMeshRenderer skinned) skinned.updateWhenOffscreen = false;
            }
        }

        private void Update()
        {
            if (motor == null || Time.timeScale == 0f) return;
            if (transform.position.z <= firstZ) direction = 1f;
            if (transform.position.z >= lastZ) direction = -1f;
            if (motor.isGrounded && verticalSpeed < 0f) verticalSpeed = -2f;
            verticalSpeed -= 20f * Time.deltaTime;
            float before = transform.position.z;
            var flags = motor.Move(new Vector3(0, verticalSpeed, direction * 1.5f) * Time.deltaTime);
            if ((flags & CollisionFlags.Below) != 0 && verticalSpeed < 0f) verticalSpeed = -2f;
            if (Mathf.Abs(transform.position.z - before) < 0.002f) blockedTime += Time.deltaTime;
            else blockedTime = 0f;
            if (blockedTime > 1.5f) { direction = -direction; blockedTime = 0f; }
            if (visual != null) visual.localRotation = Quaternion.Slerp(visual.localRotation,
                Quaternion.Euler(0, direction > 0 ? 0 : 180, 0), 6f * Time.deltaTime);
        }
    }
}
