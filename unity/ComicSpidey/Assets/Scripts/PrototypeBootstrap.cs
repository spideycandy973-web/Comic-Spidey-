using System.Collections.Generic;
using UnityEngine;

namespace ComicSpidey
{
    // Temporary test environment only; this is not the final city or game.
    public static class PrototypeBootstrap
    {
        [RuntimeInitializeOnLoadMethod(RuntimeInitializeLoadType.AfterSceneLoad)]
        private static void BuildTestWorld()
        {
            if (Object.FindObjectOfType<PrototypeController>() != null) return;
            Application.targetFrameRate = 60;
            RenderSettings.ambientLight = new Color(0.58f, 0.59f, 0.64f);
            Camera.main?.gameObject.SetActive(false);

            var light = new GameObject("Sun").AddComponent<Light>();
            light.type = LightType.Directional;
            light.transform.rotation = Quaternion.Euler(45, -35, 0);
            light.intensity = 1f;

            var groundMaterial = MakeMaterial(new Color(0.23f, 0.28f, 0.34f));
            var buildingMaterial = MakeMaterial(new Color(0.67f, 0.53f, 0.5f));
            var playerMaterial = MakeMaterial(new Color(0.12f, 0.12f, 0.14f));
            var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ground.name = "Ground";
            ground.transform.position = new Vector3(0, -0.5f, 0);
            ground.transform.localScale = new Vector3(240, 1, 240);
            ground.GetComponent<Renderer>().sharedMaterial = groundMaterial;

            var anchors = new List<Transform>();
            for (int x = -2; x <= 2; x++)
            for (int z = -2; z <= 2; z++)
            {
                // Keep a clear central intersection for spawning and input testing.
                float height = 10 + ((Mathf.Abs(x * 13 + z * 7) % 4) * 5);
                var building = GameObject.CreatePrimitive(PrimitiveType.Cube);
                building.name = "TestBuilding";
                building.transform.position = new Vector3(x * 40 + 18, height / 2, z * 40 + 18);
                building.transform.localScale = new Vector3(22, height, 22);
                building.GetComponent<Renderer>().sharedMaterial = buildingMaterial;
                var anchor = new GameObject("WebAnchor");
                anchor.transform.position = building.transform.position + Vector3.up * (height / 2 + 1);
                anchors.Add(anchor.transform);
            }

            // The first travel objective is the only playable Story milestone.
            var marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "FirstObjectiveMarker";
            marker.transform.position = new Vector3(0, 0.1f, -44);
            marker.transform.localScale = new Vector3(2f, 0.1f, 2f);
            marker.GetComponent<Renderer>().sharedMaterial = MakeMaterial(new Color(1f, 0.75f, 0.1f));
            Object.Destroy(marker.GetComponent<Collider>());

            var player = new GameObject("PrototypePlayer");
            player.transform.position = new Vector3(0, 1, 0);
            var controller = player.AddComponent<CharacterController>();
            controller.height = 2;
            controller.radius = 0.45f;
            var body = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            body.name = "PlaceholderBody";
            Object.Destroy(body.GetComponent<Collider>());
            body.transform.SetParent(player.transform, false);
            body.GetComponent<Renderer>().sharedMaterial = playerMaterial;
            var view = new GameObject("FollowCamera");
            view.tag = "MainCamera";
            view.AddComponent<Camera>();
            view.AddComponent<AudioListener>();
            player.AddComponent<PrototypeController>().Initialize(view.transform, anchors);
        }

        private static Material MakeMaterial(Color color)
        {
            var material = new Material(Shader.Find("Standard"));
            material.color = color;
            return material;
        }
    }
}
