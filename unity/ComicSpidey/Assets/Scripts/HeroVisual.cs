using UnityEngine;

namespace ComicSpidey
{
    // Reuses the supplied FBX rig and clips without making them physics objects.
    // Falls back to the existing capsule if the model or required texture fails.
    public sealed class HeroVisual : MonoBehaviour
    {
        private GameObject model;
        private Animation animationPlayer;
        private string currentClip;
        private Material suitMaterial;

        public bool Initialize(GameObject fallback)
        {
            var source = Resources.Load<GameObject>("Hero/stand");
            var texture = Resources.Load<Texture2D>("Hero/hero_diffuse");
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            if (source == null || texture == null || shader == null) return false;

            model = Instantiate(source, transform);
            model.name = "SuppliedHero";
            model.transform.localPosition = new Vector3(0, -1f, 0);
            model.transform.localRotation = Quaternion.identity;
            var renderers = model.GetComponentsInChildren<SkinnedMeshRenderer>(true);
            if (renderers.Length == 0)
            {
                Destroy(model);
                model = null;
                return false;
            }

            suitMaterial = new Material(shader) { mainTexture = texture };
            foreach (var renderer in renderers)
            {
                var materials = renderer.sharedMaterials;
                for (int i = 0; i < materials.Length; i++) materials[i] = suitMaterial;
                renderer.sharedMaterials = materials;
                renderer.updateWhenOffscreen = false;
            }

            // Normalize imported FBX units to the two-metre collision capsule.
            var bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Length; i++) bounds.Encapsulate(renderers[i].bounds);
            if (bounds.size.y > 0.001f)
            {
                model.transform.localScale *= 1.8f / bounds.size.y;
                bounds = renderers[0].bounds;
                for (int i = 1; i < renderers.Length; i++) bounds.Encapsulate(renderers[i].bounds);
                model.transform.position += Vector3.up * (transform.position.y - 1f - bounds.min.y);
            }
            animationPlayer = model.GetComponent<Animation>();
            if (animationPlayer == null) animationPlayer = model.AddComponent<Animation>();
            animationPlayer.playAutomatically = false;
            AddClip("stand", WrapMode.Loop);
            AddClip("run", WrapMode.Loop);
            AddClip("hanging", WrapMode.Loop);
            Play("stand");
            fallback.SetActive(false);
            return true;
        }

        private void AddClip(string resourceName, WrapMode wrap)
        {
            foreach (var clip in Resources.LoadAll<AnimationClip>("Hero/" + resourceName))
            {
                if (clip == null || clip.name.StartsWith("__preview__") || !clip.legacy) continue;
                animationPlayer.AddClip(clip, resourceName);
                animationPlayer[resourceName].wrapMode = wrap;
                return;
            }
        }

        public void UpdateMotion(bool grounded, bool tethered, Vector3 velocity)
        {
            if (animationPlayer == null) return;
            var horizontal = new Vector2(velocity.x, velocity.z).sqrMagnitude;
            Play(tethered ? "hanging" : (grounded && horizontal > 0.4f ? "run" : "stand"));
        }

        private void Play(string name)
        {
            if (animationPlayer == null || currentClip == name || animationPlayer[name] == null) return;
            animationPlayer.CrossFade(name, 0.12f);
            currentClip = name;
        }

        private void OnDestroy()
        {
            if (suitMaterial != null) Destroy(suitMaterial);
        }
    }
}
