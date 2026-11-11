using UnrealBuildTool;
using System.Collections.Generic;

public class ComicSpideyEditorTarget : TargetRules
{
    public ComicSpideyEditorTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Editor;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ComicSpidey");
    }
}
