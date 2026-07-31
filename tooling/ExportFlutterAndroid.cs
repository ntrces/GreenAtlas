using System;
using UnityEditor;

public static class ExportFlutterAndroid
{
    public static void Export()
    {
        if (!EditorApplication.ExecuteMenuItem(
                "Flutter Embed/Export project to flutter app (Android)"))
        {
            throw new InvalidOperationException(
                "Flutter Embed Android export command was not available.");
        }
    }
}
