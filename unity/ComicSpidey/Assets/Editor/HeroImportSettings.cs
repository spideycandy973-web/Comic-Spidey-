using UnityEditor;

// The supplied files have the same Mixamo skeleton. Import their clips as
// Legacy so the prototype can play them without an editor-authored controller.
// A proper retargeted Animator controller will replace this prototype setup.
public sealed class HeroImportSettings : AssetPostprocessor
{
    private void OnPreprocessModel()
    {
        if (!assetPath.StartsWith("Assets/Resources/Hero/", System.StringComparison.OrdinalIgnoreCase)) return;
        var importer = (ModelImporter)assetImporter;
        importer.animationType = ModelImporterAnimationType.Legacy;
        importer.importAnimation = true;
        importer.materialImportMode = ModelImporterMaterialImportMode.None;
    }
}
