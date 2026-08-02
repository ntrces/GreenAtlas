using System;
using UnityEditor;
using UnityEditor.SceneManagement;
using UnityEditor.XR.ARCore;
using UnityEngine;

public static class ConfigureArExperience
{
    public static void Configure()
    {
        const string scenePath = "Assets/Scenes/GreenAtlasAR.unity";
        var scene = EditorSceneManager.OpenScene(scenePath);
        var anchor = GameObject.Find("Plant_Anchor");
        if (anchor == null)
            throw new InvalidOperationException("Plant_Anchor was not found.");

        var experience = anchor.GetComponent<InteractivePlantAR>();
        if (experience == null)
            throw new InvalidOperationException(
                "InteractivePlantAR is not attached to Plant_Anchor.");

        var sprout = AssetDatabase.LoadAssetAtPath<GameObject>(
            "Assets/Prefabs/sprout.glb");
        if (sprout == null)
        {
            sprout = AssetDatabase.LoadAssetAtPath<GameObject>(
                "Assets/Models/sprout.glb");
        }
        if (sprout == null)
            throw new InvalidOperationException("The sprout prefab was not found.");

        var serialized = new SerializedObject(experience);
        var planeManager = UnityEngine.Object.FindFirstObjectByType<
            UnityEngine.XR.ARFoundation.ARPlaneManager>();
        serialized.FindProperty("planeManager").objectReferenceValue = planeManager;
        serialized.FindProperty("sproutPrefab").objectReferenceValue = sprout;
        var species = serialized.FindProperty("species");
        for (var i = 0; i < species.arraySize; i++)
            species.GetArrayElementAtIndex(i)
                .FindPropertyRelative("prefab").objectReferenceValue = null;
        serialized.FindProperty("growthDistanceMeters").floatValue = 2f;
        serialized.FindProperty("growthAnimationSeconds").floatValue = 2.2f;
        serialized.ApplyModifiedPropertiesWithoutUndo();

        EditorUtility.SetDirty(experience);
        EditorSceneManager.MarkSceneDirty(scene);
        EditorSceneManager.SaveScene(scene);
        AssetDatabase.SaveAssets();

        var arCoreSettings = ARCoreSettings.GetOrCreateSettings();
        arCoreSettings.requirement = ARCoreSettings.Requirement.Optional;
        arCoreSettings.depth = ARCoreSettings.Requirement.Optional;
        EditorUtility.SetDirty(arCoreSettings);
        AssetDatabase.SaveAssets();

        Debug.Log("Configured optional ARCore and downloadable mature-tree content.");
    }
}
