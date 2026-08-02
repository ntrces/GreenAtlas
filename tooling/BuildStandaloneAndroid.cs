using System;
using System.Linq;
using UnityEditor;
using UnityEditor.Build.Reporting;

public static class BuildStandaloneAndroid
{
    public static void Build()
    {
        var scenes = EditorBuildSettings.scenes
            .Where(scene => scene.enabled)
            .Select(scene => scene.path)
            .ToArray();

        if (scenes.Length == 0)
        {
            throw new InvalidOperationException("No enabled scenes are configured.");
        }

        var output = Environment.GetEnvironmentVariable("GREENATLAS_STANDALONE_APK");
        if (string.IsNullOrWhiteSpace(output))
        {
            throw new InvalidOperationException(
                "GREENATLAS_STANDALONE_APK was not provided.");
        }

        var report = BuildPipeline.BuildPlayer(new BuildPlayerOptions
        {
            scenes = scenes,
            locationPathName = output,
            target = BuildTarget.Android,
            options = BuildOptions.Development
        });

        if (report.summary.result != BuildResult.Succeeded)
        {
            throw new InvalidOperationException(
                $"Standalone Android build failed: {report.summary.result}");
        }
    }
}
