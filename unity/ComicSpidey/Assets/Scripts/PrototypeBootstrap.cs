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
#if UNITY_ANDROID || UNITY_IOS
            // The prototype uses a wide third-person layout, not a portrait UI.
            Screen.orientation = ScreenOrientation.LandscapeLeft;
#endif
            RenderSettings.ambientLight = new Color(0.58f, 0.59f, 0.64f);
            Camera.main?.gameObject.SetActive(false);

            var light = new GameObject("Sun").AddComponent<Light>();
            light.type = LightType.Directional;
            light.transform.rotation = Quaternion.Euler(45, -35, 0);
            light.intensity = 1f;

            var groundMaterial = MakeMaterial(new Color(0.23f, 0.28f, 0.34f));
            var buildingMaterial = MakeBuildingMaterial();
            var roadMaterial = MakeMaterial(new Color(0.12f, 0.15f, 0.20f));
            var markingMaterial = MakeMaterial(new Color(0.94f, 0.75f, 0.39f));
            var playerMaterial = MakeMaterial(new Color(0.12f, 0.12f, 0.14f));
            var ground = GameObject.CreatePrimitive(PrimitiveType.Cube);
            ground.name = "Ground";
            ground.transform.position = new Vector3(0, -0.5f, 0);
            ground.transform.localScale = new Vector3(240, 1, 240);
            ground.GetComponent<Renderer>().sharedMaterial = groundMaterial;

            // Lightweight street markings and window textures make the test
            // environment readable; these are still temporary geometry.
            for (int street = -2; street <= 3; street++)
            {
                float offset = street * 40 - 2;
                AddDecoration("Road", new Vector3(offset, 0.01f, 0), new Vector3(14, 0.02f, 240), roadMaterial);
                AddDecoration("Road", new Vector3(0, 0.02f, offset), new Vector3(240, 0.02f, 14), roadMaterial);
                for (int dash = -5; dash <= 5; dash++)
                {
                    AddDecoration("LaneMark", new Vector3(offset, 0.04f, dash * 20), new Vector3(0.22f, 0.02f, 4), markingMaterial);
                    AddDecoration("LaneMark", new Vector3(dash * 20, 0.05f, offset), new Vector3(4, 0.02f, 0.22f), markingMaterial);
                }
            }

            var anchors = new List<Transform>();
            for (int x = -2; x <= 2; x++)
            for (int z = -2; z <= 2; z++)
            {
                // Keep a clear central intersection for spawning and input testing.
                float height = 10 + ((Mathf.Abs(x * 13 + z * 7) % 4) * 5);
                var building = GameObject.CreatePrimitive(PrimitiveType.Cube);
                building.name = "TestBuilding";
                building.AddComponent<ClimbableSurface>();
                building.transform.position = new Vector3(x * 40 + 18, height / 2, z * 40 + 18);
                building.transform.localScale = new Vector3(22, height, 22);
                building.GetComponent<Renderer>().sharedMaterial = buildingMaterial;
                var anchor = new GameObject("WebAnchor");
                anchor.transform.position = building.transform.position + Vector3.up * (height / 2 + 1);
                anchors.Add(anchor.transform);
            }

            AddSuppliedRoads();
            AddSuppliedStreetLights();
            AddTestPedestrians();
            PrototypeVehicleDisplay.Place();

            // Temporary test objective and highly visible beacon; not campaign mission 1.
            var marker = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            marker.name = "FirstObjectiveMarker";
            marker.transform.position = new Vector3(0, 0.1f, -44);
            marker.transform.localScale = new Vector3(2f, 0.1f, 2f);
            marker.GetComponent<Renderer>().sharedMaterial = MakeMaterial(new Color(1f, 0.75f, 0.1f));
            Object.Destroy(marker.GetComponent<Collider>());
            var beacon = GameObject.CreatePrimitive(PrimitiveType.Cylinder);
            beacon.name = "ObjectiveBeacon";
            beacon.transform.SetParent(marker.transform, false);
            beacon.transform.localPosition = new Vector3(0, 22f, 0);
            beacon.transform.localScale = new Vector3(0.25f, 22f, 0.25f);
            beacon.GetComponent<Renderer>().sharedMaterial = marker.GetComponent<Renderer>().sharedMaterial;
            Object.Destroy(beacon.GetComponent<Collider>());

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
            player.AddComponent<HeroVisual>().Initialize(body);
            var view = new GameObject("FollowCamera");
            view.tag = "MainCamera";
            var camera = view.AddComponent<Camera>();
            view.AddComponent<AudioListener>();
            var settings = player.AddComponent<PrototypeSettings>();
            settings.Initialize(camera, light);
            var playerController = player.AddComponent<PrototypeController>();
            playerController.Initialize(view.transform, anchors);
            var modeMenu = player.AddComponent<PrototypeModeMenu>();
            playerController.InitializeModeMenu(modeMenu);
            modeMenu.Initialize(playerController, settings, marker);
        }

        private static void AddSuppliedRoads()
        {
            var source = Resources.Load<GameObject>("City/road_strip");
            var texture = Resources.Load<Texture2D>("City/road_strip");
            var filter = source != null ? source.GetComponentInChildren<MeshFilter>() : null;
            if (filter == null || filter.sharedMesh == null || texture == null) return;
            var material = MakeMaterial(Color.white);
            material.mainTexture = texture;
            // Batch strips per street so the supplied mesh doesn't add hundreds
            // of individual draw calls. The original cube roads remain as a
            // fallback and supply the ground collision. This is a test layout.
            for (int street = -2; street <= 3; street++)
            for (int axis = 0; axis < 2; axis++)
            {
                var pieces = new List<CombineInstance>();
                float center = street * 40 - 2;
                for (int segment = 0; segment < 20; segment++)
                for (int lane = 0; lane < 4; lane++)
                {
                    float along = -120 + segment * 12;
                    float across = center + (lane - 1.5f) * 3.3f;
                    var position = axis == 0 ? new Vector3(across, 0.07f, along) : new Vector3(along, 0.09f, across);
                    var rotation = axis == 0 ? Quaternion.identity : Quaternion.Euler(0, 90, 0);
                    pieces.Add(new CombineInstance { mesh = filter.sharedMesh,
                        transform = Matrix4x4.TRS(position, rotation, new Vector3(1.5f, 1, 2)) });
                }
                var combined = new Mesh { name = "NeighborhoodRoadBatch" };
                combined.CombineMeshes(pieces.ToArray(), true, true);
                var road = new GameObject("SuppliedRoadBatch");
                road.AddComponent<MeshFilter>().sharedMesh = combined;
                road.AddComponent<MeshRenderer>().sharedMaterial = material;
            }
        }

        private static void AddTestPedestrians()
        {
            for (int i = 0; i < 4; i++)
            {
                var pedestrian = new GameObject("TestPedestrian" + i);
                float lane = i < 2 ? -9.7f : 4.7f;
                pedestrian.transform.position = new Vector3(lane, 0.05f, i % 2 == 0 ? -60f : 60f);
                var motor = pedestrian.AddComponent<CharacterController>();
                motor.height = 1.8f;
                motor.radius = 0.32f;
                motor.center = new Vector3(0, 0.9f, 0);
                pedestrian.AddComponent<PrototypeCitizen>().Initialize(i % 2 == 0 ? "citizen" : "citizen2",
                    -65f, 65f, i % 2 == 0 ? 1f : -1f);
            }
        }

        private static void AddSuppliedStreetLights()
        {
            var source = Resources.Load<GameObject>("City/street-light");
            var texture = Resources.Load<Texture2D>("City/street-light");
            if (source == null || texture == null) return;
            var material = MakeMaterial(Color.white);
            material.mainTexture = texture;
            // The supplied model uses centimetre-scale coordinates. Pole-only
            // collision is approximate and needs physical-device verification.
            for (int i = -2; i <= 2; i++)
            {
                var light = Object.Instantiate(source);
                light.name = "SuppliedStreetLight";
                light.transform.position = new Vector3(6f, 0.087f, i * 20f);
                light.transform.localScale = Vector3.one * 0.01f;
                foreach (var renderer in light.GetComponentsInChildren<Renderer>())
                    renderer.sharedMaterial = material;
                var pole = light.AddComponent<BoxCollider>();
                pole.center = new Vector3(0, 290, 0);
                pole.size = new Vector3(14, 580, 14);
            }
        }

        private static void AddDecoration(string name, Vector3 position, Vector3 scale, Material material)
        {
            var item = GameObject.CreatePrimitive(PrimitiveType.Cube);
            item.name = name;
            item.transform.position = position;
            item.transform.localScale = scale;
            item.GetComponent<Renderer>().sharedMaterial = material;
            Object.Destroy(item.GetComponent<Collider>());
        }

        private static Material MakeBuildingMaterial()
        {
            var material = MakeMaterial(Color.white);
            var texture = new Texture2D(64, 64, TextureFormat.RGB24, false);
            texture.filterMode = FilterMode.Point;
            for (int y = 0; y < 64; y++)
            for (int x = 0; x < 64; x++)
            {
                bool window = x % 16 >= 3 && x % 16 <= 12 && y % 16 >= 3 && y % 16 <= 12;
                bool lit = ((x / 16 * 3 + y / 16 * 7) % 3) != 0;
                texture.SetPixel(x, y, window ? (lit ? new Color(0.55f, 0.72f, 0.78f) : new Color(0.13f, 0.23f, 0.33f)) : new Color(0.34f, 0.30f, 0.36f));
            }
            texture.Apply();
            material.mainTexture = texture;
            return material;
        }

        private static Material MakeMaterial(Color color)
        {
            var material = new Material(Resources.Load<Shader>("Hero/HeroLit"));
            material.color = color;
            return material;
        }
    }
}
