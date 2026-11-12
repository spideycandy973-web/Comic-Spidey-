using System;
using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Static, parked asset previews only: there is no traffic or emergency AI.
    public static class PrototypeVehicleDisplay
    {
        private struct Vehicle
        {
            public string mesh, albedo, decal;
            public float length;
            public Vehicle(string m, string a, string d, float l) { mesh = m; albedo = a; decal = d; length = l; }
        }
        private static readonly Vehicle[] Fleet = {
            new Vehicle("ambulance", "ambulance", "ambulance_decals", 6.5f),
            new Vehicle("citybus", "citybus", "CityBusDecals", 10f),
            new Vehicle("fire_truck", "firetruck", "FireTruckDecals", 8f),
            new Vehicle("garbage_truck", "garbagetruck", null, 7.5f),
            new Vehicle("police_sedan", "police", "Police_decals", 5f),
            new Vehicle("rdservtruck", "servicetruck", "rdservtruck_decal", 5.5f),
            new Vehicle("school_bus", "schoolbus", "SchoolBus_decals", 8f),
            new Vehicle("taxi", "taxi", "taxi_decals", 5f),
            new Vehicle("towtruck", "towtruck", null, 6.5f),
            new Vehicle("postvan", "postvan", "postvan_decal", 5.5f)
        };

        public static void Place()
        {
            var source = Resources.Load<GameObject>("Vehicles/fleet");
            var shader = Resources.Load<Shader>("Hero/HeroLit");
            if (source == null || shader == null) return;
            var assembly = UnityEngine.Object.Instantiate(source);
            assembly.name = "VehicleImportTemporaryRoot";
            var all = assembly.GetComponentsInChildren<MeshRenderer>(true);
            var materials = new Dictionary<string, Material>();
            for (int i = 0; i < Fleet.Length; i++)
            {
                var vehicle = Fleet[i];
                MeshRenderer found = null;
                foreach (var renderer in all)
                    if (renderer != null && string.Equals(renderer.gameObject.name, vehicle.mesh, StringComparison.OrdinalIgnoreCase))
                    { found = renderer; break; }
                if (found == null) { Debug.LogWarning("Vehicle mesh missing: " + vehicle.mesh); continue; }
                var bounds = found.bounds;
                float longest = Mathf.Max(bounds.size.x, bounds.size.z);
                if (longest < 0.001f) { Debug.LogWarning("Vehicle has empty bounds: " + vehicle.mesh); continue; }
                // Detach each mesh from the imported presentation layout and
                // size it by its measured bounds, preserving its import rotation.
                var holder = new GameObject("Parked_" + vehicle.mesh);
                holder.transform.position = bounds.center;
                found.transform.SetParent(holder.transform, true);
                holder.transform.localScale = Vector3.one * (vehicle.length / longest);
                bounds = found.bounds;
                float lane = i % 2 == 0 ? -6.5f : 2.5f;
                float z = -85f + (i / 2) * 40f;
                holder.transform.position += new Vector3(lane - bounds.center.x, -bounds.min.y + 0.05f, z - bounds.center.z);
                bounds = found.bounds;
                var collider = holder.AddComponent<BoxCollider>();
                collider.center = holder.transform.InverseTransformPoint(bounds.center);
                collider.size = bounds.size / holder.transform.localScale.x;
                var slots = found.sharedMaterials;
                for (int j = 0; j < slots.Length; j++)
                {
                    string name = slots[j] != null ? slots[j].name.ToLowerInvariant() : "";
                    string textureName = name.Contains("glass") ? null : name.Contains("decal") ? vehicle.decal :
                        name.Contains("optic") ? "CSPOptics" : vehicle.albedo + "_albedo";
                    string key = textureName ?? "glass";
                    if (!materials.TryGetValue(key, out Material material))
                    {
                        material = new Material(shader);
                        var texture = textureName != null ? Resources.Load<Texture2D>("Vehicles/" + textureName) : null;
                        material.mainTexture = texture;
                        material.color = textureName == null ? new Color(0.18f, 0.25f, 0.30f) : Color.white;
                        materials.Add(key, material);
                    }
                    slots[j] = material;
                }
                found.sharedMaterials = slots;
            }
            // The visible meshes have been reparented; remove any unused import nodes.
            UnityEngine.Object.Destroy(assembly);
        }
    }
}
