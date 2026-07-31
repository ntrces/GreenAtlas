# Unity integration for GreenAtlas

The Flutter side uses `flutter_embed_unity` 2.0.0. `ar_view.dart` is the only
production AR screen and sends:

```text
GameObject: Plant_Anchor
Method:     LoadSelectedSpecies
Data:       <Scientific_name_with_underscores>
```

## Supported Unity version

`flutter_embed_unity` 2.0.0 supports Unity 6000.0 LTS and 6000.3 LTS. Unity
6000.4 ("Unity 6.4") is not listed as supported by the plugin and should not be
used for this integration unless the plugin adds explicit support. Use Unity
6000.3.11f1 or a newer supported 6000.3 release. For Android, the plugin also
requires at least 6000.3.0f1 (or 6000.0.58f2).

## Unity project setup

1. Install the plugin's Unity 6 package with Unity Package Manager using:
   `https://github.com/learntoflutter/flutter_embed_unity.git?path=example_unity_6000_0_project/Assets/FlutterEmbed`
2. Keep one active AR scene. Add the AR Foundation, ARCore XR Plugin, and ARKit
   XR Plugin packages appropriate for the supported Unity editor.
3. Put the component containing this public method on a GameObject named
   `Plant_Anchor`:

   ```csharp
   public void LoadSelectedSpecies(string speciesID)
   {
       // Select or instantiate the matching species prefab.
   }
   ```

4. Add this component to an object that is active when the AR scene loads:

   ```csharp
   using UnityEngine;
   using UnityEngine.SceneManagement;

   public sealed class FlutterSceneReady : MonoBehaviour
   {
       private void OnEnable() => SceneManager.sceneLoaded += OnSceneLoaded;
       private void OnDisable() => SceneManager.sceneLoaded -= OnSceneLoaded;

       private void Start() => SendToFlutter.Send("scene_loaded");

       private static void OnSceneLoaded(Scene scene, LoadSceneMode mode) =>
           SendToFlutter.Send("scene_loaded");
   }
   ```

5. In Build Profiles, select Android, enable **Export Project**, use IL2CPP,
   enable ARMv7 and ARM64, and match the Flutter app's target API where
   practical.
6. Create `android/unityLibrary`, then use **Flutter Embed > Export project to
   Flutter app** and select that exact directory. The plugin export tooling
   applies the required Gradle changes.
7. For iOS, export to `ios/unityLibrary`. In Xcode, add
   `Unity-iPhone/UnityFramework.framework` to Runner as **Embed & Sign**, then
   place Flutter's **Thin Binary** build phase below **Embed Frameworks**.

## Current repository state

`android/settings.gradle.kts` already includes `:unityLibrary`, but that
directory is currently absent. `android/unityLibrary_old` is an old generated
export and is intentionally not wired into the build. Re-export the supported
Unity project to `android/unityLibrary` before building or running Android.
