using UnityEditor;

// The prototype combines copies of this small road mesh at runtime. Unity must
// keep its vertex data readable in the Android player for CombineMeshes.
public sealed class CityImportSettings : AssetPostprocessor
{
    private void OnPreprocessModel()
    {
        if (!assetPath.Equals("Assets/Resources/City/road_strip.obj", System.StringComparison.OrdinalIgnoreCase)) return;
        var importer = (ModelImporter)assetImporter;
        importer.isReadable = true;
        importer.materialImportMode = ModelImporterMaterialImportMode.None;
    }
}
