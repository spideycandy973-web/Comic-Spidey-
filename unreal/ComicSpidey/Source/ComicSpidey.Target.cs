using UnrealBuildTool;
using System.Collections.Generic;

public class ComicSpideyTarget : TargetRules
{
    public ComicSpideyTarget(TargetInfo Target) : base(Target)
    {
        Type = TargetType.Game;
        DefaultBuildSettings = BuildSettingsVersion.V5;
        ExtraModuleNames.Add("ComicSpidey");
    }
}
