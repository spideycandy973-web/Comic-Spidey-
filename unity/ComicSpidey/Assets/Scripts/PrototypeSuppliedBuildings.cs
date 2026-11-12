using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // One supplied neighborhood building, repeated only four times in the
    // small test world. This is neither the whole city nor the final art pass.
    public sealed class PrototypeSuppliedBuildings
    {
        private readonly GameObject[] parts = new GameObject[4];
        private readonly Material[] materials = new Material[3];
        private static readonly string[] PartNames = { "windows_a", "windows_b", "wall_lower", "wall_upper" };
        private static readonly string[] TextureNames = { "windows", "wall_lower", "wall_upper" };

        public bool Prepare()
        {
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            if (shader == null) return false;
            var textures = new Texture2D[3];
            for (int i = 0; i < parts.Length; i++)
            {
                parts[i] = Resources.Load<GameObject>("City/Building/" + PartNames[i]);
                if (parts[i] == null) return false;
            }
            for (int i = 0; i < textures.Length; i++)
            {
                textures[i] = Resources.Load<Texture2D>("City/Building/" + TextureNames[i]);
                if (textures[i] == null) return false;
            }
            for (int i = 0; i < materials.Length; i++)
            {
                materials[i] = new Material(shader) { mainTexture = textures[i], color = Color.white };
                // Supplied building materials are double-sided in the source GLB.
                materials[i].SetFloat("_Cull", 0);
            }
            return true;
        }

        public bool TryCreate(Vector3 center, List<Transform> anchors)
        {
            var building = new GameObject("SuppliedNeighborhoodBuilding");
            building.transform.position = center;
            var visual = new GameObject("BuildingVisual");
            visual.transform.SetParent(building.transform, false);
            var renderers = new List<Renderer>();
            for (int i = 0; i < parts.Length; i++)
            {
                var part = Object.Instantiate(parts[i], visual.transform);
                foreach (var collider in part.GetComponentsInChildren<Collider>()) Object.Destroy(collider);
                foreach (var renderer in part.GetComponentsInChildren<Renderer>())
                {
                    renderer.sharedMaterial = materials[i < 2 ? 0 : i - 1];
                    renderers.Add(renderer);
                }
            }
            if (renderers.Count == 0) { Object.Destroy(building); return false; }
            var bounds = CombinedBounds(renderers);
            float horizontalExtent = Mathf.Max(bounds.size.x, bounds.size.z);
            if (horizontalExtent < 0.001f || bounds.size.y < 0.001f)
            { Object.Destroy(building); return false; }
            // Retain proportions and fit within the existing city block. The
            // bounding box is intentionally approximate, not detailed collision.
            visual.transform.localScale = Vector3.one * (20f / horizontalExtent);
            bounds = CombinedBounds(renderers);
            visual.transform.position += new Vector3(center.x - bounds.center.x, -bounds.min.y, center.z - bounds.center.z);
            bounds = CombinedBounds(renderers);
            var collision = building.AddComponent<BoxCollider>();
            collision.center = building.transform.InverseTransformPoint(bounds.center);
            collision.size = bounds.size;
            building.AddComponent<ClimbableSurface>();
            var anchor = new GameObject("WebAnchor");
            anchor.transform.position = new Vector3(bounds.center.x, bounds.max.y + 1f, bounds.center.z);
            anchors.Add(anchor.transform);
            return true;
        }

        private static Bounds CombinedBounds(List<Renderer> renderers)
        {
            var bounds = renderers[0].bounds;
            for (int i = 1; i < renderers.Count; i++) bounds.Encapsulate(renderers[i].bounds);
            return bounds;
        }
    }
}
