using UnityEditor;

// Temporary Legacy clip import for the supplied hero and generated citizens.
// A retargeted Animator controller and Unity/device validation remain needed.
public sealed class HeroImportSettings : AssetPostprocessor
{
    private void OnPreprocessModel()
    {
        bool hero = assetPath.StartsWith("Assets/Resources/Hero/", System.StringComparison.OrdinalIgnoreCase);
        bool citizen = assetPath.StartsWith("Assets/Resources/Citizens/", System.StringComparison.OrdinalIgnoreCase);
        if (!hero && !citizen) return;
        var importer = (ModelImporter)assetImporter;
        importer.animationType = ModelImporterAnimationType.Legacy;
        importer.importAnimation = true;
        // Citizens have embedded colour materials; the hero uses a separate texture.
        if (hero) importer.materialImportMode = ModelImporterMaterialImportMode.None;
    }
}
