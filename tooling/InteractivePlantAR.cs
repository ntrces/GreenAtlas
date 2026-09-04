using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using GLTFast;
using UnityEngine;
using UnityEngine.InputSystem.EnhancedTouch;
using UnityEngine.XR.ARFoundation;
using UnityEngine.XR.ARSubsystems;
using Touch = UnityEngine.InputSystem.EnhancedTouch.Touch;

public sealed class InteractivePlantAR : MonoBehaviour
{
    [Serializable]
    public sealed class SpeciesEntry
    {
        public string speciesID;
        public GameObject prefab;
    }

    [SerializeField] private ARRaycastManager raycastManager;
    [SerializeField] private ARPlaneManager planeManager;
    [SerializeField] private GameObject sproutPrefab;
    [SerializeField] private List<SpeciesEntry> species = new();
    private const float GrowthDistanceMeters = 1.5f;
    [SerializeField, Min(0.1f)] private float growthAnimationSeconds = 2.2f;
    [SerializeField, Min(1f)] private float matureTreeHeightMeters = 3.5f;
    [SerializeField, Min(1)] private int requiredWaterings = 3;

    private static readonly List<ARRaycastHit> Hits = new();
    private GltfImport selectedGltf;
    private string selectedSpeciesID;
    private string selectedModelPath;
    private bool modelReady;
    private GameObject placedPlant;
    private Pose placementPose;
    private bool hasPlacement;
    private bool watered;
    private int wateringCount;
    private bool growthStarted;
    private bool growthComplete;
    private bool reportedReady;
    private int lastDistanceDecimeter = -1;
    private Vector3 sproutBaseScale;
    private Camera arCamera;
    private AudioSource ambientSource;
    private AudioSource effectSource;
    private AudioSource shimmerSource;
    private AudioClip splashClip;
    private AudioClip bloomClip;

    private void Awake()
    {
        if (raycastManager == null)
            raycastManager = FindFirstObjectByType<ARRaycastManager>();
        if (planeManager == null)
            planeManager = FindFirstObjectByType<ARPlaneManager>();
        arCamera = Camera.main;
        CreateAudioExperience();
        ShowPlanes(false);
    }

    private void OnEnable()
    {
        EnhancedTouchSupport.Enable();
        ARSession.stateChanged += OnArSessionStateChanged;
    }

    private void Start()
    {
        SendToFlutter.Send("scene_loaded");
        ReportArState(ARSession.state);
    }

    private void OnDisable()
    {
        ARSession.stateChanged -= OnArSessionStateChanged;
        EnhancedTouchSupport.Disable();
    }

    private void OnDestroy()
    {
        selectedGltf?.Dispose();
    }

    private void OnArSessionStateChanged(ARSessionStateChangedEventArgs args)
    {
        ReportArState(args.state);
    }

    private void ReportArState(ARSessionState state)
    {
        switch (state)
        {
            case ARSessionState.SessionTracking:
                if (!reportedReady)
                {
                    reportedReady = true;
                    SendToFlutter.Send("ar_ready");
                    FadeAudio(ambientSource, 0.14f, 1.5f);
                }
                break;
            case ARSessionState.Unsupported:
                SendToFlutter.Send("error:This device does not support ARCore.");
                break;
            case ARSessionState.NeedsInstall:
                SendToFlutter.Send("status:Google Play Services for AR needs permission to install.");
                break;
            case ARSessionState.Installing:
                SendToFlutter.Send("status:Installing Google Play Services for AR…");
                break;
            case ARSessionState.CheckingAvailability:
                SendToFlutter.Send("status:Checking ARCore compatibility…");
                break;
            case ARSessionState.Ready:
            case ARSessionState.SessionInitializing:
                SendToFlutter.Send("status:Starting camera tracking…");
                break;
        }
    }

    private void Update()
    {
        if (Time.frameCount % 20 == 0)
            ShowPlanes(false);

        if (watered && !growthStarted && hasPlacement)
            UpdateProximityGrowth();

        if (!modelReady || Touch.activeTouches.Count == 0)
            return;

        Touch touch = Touch.activeTouches[0];
        if (touch.phase != UnityEngine.InputSystem.TouchPhase.Began)
            return;

        if (!hasPlacement)
        {
            if (raycastManager.Raycast(touch.screenPosition, Hits, TrackableType.PlaneWithinPolygon))
                PlaceSprout(Hits[0].pose);
            else
                SendToFlutter.Send("status:No surface found—move slowly over a textured floor.");
            return;
        }

        if (arCamera == null)
            arCamera = Camera.main;
        if (arCamera == null)
            return;

        Ray ray = arCamera.ScreenPointToRay(touch.screenPosition);
        RaycastHit[] hits = Physics.RaycastAll(ray, 100f);
        if (hits.Length == 0)
            return;

        RaycastHit hit = hits[0];
        if (!growthComplete && placedPlant != null && hit.transform.IsChildOf(placedPlant.transform))
            NurtureSprout();
    }

    public void LoadSelectedSpecies(string payload)
    {
        string[] parts = payload.Split(new[] { '|' }, 2);
        string speciesID = parts[0];
        string location = parts.Length > 1 ? parts[1] : string.Empty;
        ClearPlacedExperience();
        selectedGltf?.Dispose();
        selectedGltf = null;
        selectedSpeciesID = speciesID;
        selectedModelPath = string.Empty;
        modelReady = false;

        if (TryResolveLocalPath(location, out string localPath) && File.Exists(localPath))
        {
            selectedModelPath = localPath;
            StartCoroutine(LoadCachedModel());
            return;
        }

        selectedModelPath = GetCachedModelPath(speciesID);
        if (File.Exists(selectedModelPath))
        {
            StartCoroutine(LoadCachedModel());
            return;
        }

        SendToFlutter.Send(
            $"error:The downloaded AR model for {speciesID} was not found. Return to the shelf and download it again.");
    }

    public void DownloadSelectedSpecies(string ignored)
    {
        SendToFlutter.Send(
            "error:Download this species from the Botanical Shelf before opening AR.");
    }

    public void WaterPlant(string ignored)
    {
        NurtureSprout();
    }

    public void ResetPlant(string ignored)
    {
        ClearPlacedExperience();
        ShowPlanes(false);
        SendToFlutter.Send("status:Move slowly to find a flat floor, then tap to place the sprout.");
    }

    public void StopExperience(string ignored)
    {
        FadeAudio(ambientSource, 0f, 0.8f);
        FadeAudio(shimmerSource, 0f, 0.5f);
        effectSource.Stop();
    }

    private void PlaceSprout(Pose pose)
    {
        if (sproutPrefab == null)
        {
            SendToFlutter.Send("error:The local sprout model is missing.");
            return;
        }

        ClearPlacedExperience();
        placementPose = pose;
        placedPlant = Instantiate(sproutPrefab, pose.position, pose.rotation, transform);
        sproutBaseScale = placedPlant.transform.localScale;
        AddInteractionCollider(placedPlant);
        hasPlacement = true;
        ShowPlanes(false);
        effectSource.transform.position = pose.position;
        shimmerSource.transform.position = pose.position;
        SendToFlutter.Send("plant_placed");
        SendToFlutter.Send($"growth:0/{requiredWaterings}");
        SendToFlutter.Send($"status:Sprout anchored—water it {requiredWaterings} times.");
    }

    private void NurtureSprout()
    {
        if (!hasPlacement || placedPlant == null || watered || growthComplete)
            return;

        wateringCount = Mathf.Min(wateringCount + 1, requiredWaterings);
        CreateWaterParticles(placedPlant);
        effectSource.PlayOneShot(splashClip, 0.9f);
        StartCoroutine(PulseGlow(placedPlant));
        SendToFlutter.Send($"growth:{wateringCount}/{requiredWaterings}");

        if (wateringCount < requiredWaterings)
        {
            int remaining = requiredWaterings - wateringCount;
            SendToFlutter.Send($"status:Water absorbed—{remaining} more {(remaining == 1 ? "watering" : "waterings")} needed.");
            return;
        }

        watered = true;
        lastDistanceDecimeter = -1;
        shimmerSource.volume = 0.04f;
        shimmerSource.pitch = 0.75f;
        if (!shimmerSource.isPlaying)
            shimmerSource.Play();
        SendToFlutter.Send("status:The sprout is fully watered—step backward and listen as it gathers strength.");
    }

    private void UpdateProximityGrowth()
    {
        if (arCamera == null)
            arCamera = Camera.main;
        if (arCamera == null)
            return;

        float distance = Vector3.Distance(arCamera.transform.position, placementPose.position);
        float progress = Mathf.Clamp01(distance / GrowthDistanceMeters);
        shimmerSource.volume = Mathf.Lerp(0.04f, 0.5f, progress);
        shimmerSource.pitch = Mathf.Lerp(0.75f, 1.65f, progress);
        int decimeter = Mathf.FloorToInt(Mathf.Min(distance, GrowthDistanceMeters) * 10f);
        if (decimeter != lastDistanceDecimeter)
        {
            lastDistanceDecimeter = decimeter;
            SendToFlutter.Send($"growth_distance:{Mathf.Min(distance, GrowthDistanceMeters):0.0}");
        }

        if (distance >= GrowthDistanceMeters)
        {
            growthStarted = true;
            StartCoroutine(TransformIntoMatureTree());
        }
    }

    private IEnumerator TransformIntoMatureTree()
    {
        shimmerSource.Stop();
        effectSource.PlayOneShot(bloomClip, 1f);
        yield return AnimateScale(
            placedPlant.transform,
            placedPlant.transform.localScale,
            sproutBaseScale * 2f,
            0.7f);

        Destroy(placedPlant);
        placedPlant = null;
        if (selectedGltf == null)
        {
            SendToFlutter.Send("error:The downloaded tree is not ready. Return to the shelf and try again.");
            yield break;
        }

        placedPlant = new GameObject($"{selectedSpeciesID}_MatureTree");
        placedPlant.transform.SetParent(transform, false);
        placedPlant.transform.SetPositionAndRotation(placementPose.position, placementPose.rotation);
        Task<bool> task = selectedGltf.InstantiateMainSceneAsync(placedPlant.transform);
        while (!task.IsCompleted)
            yield return null;
        if (task.IsFaulted || !task.Result)
        {
            Destroy(placedPlant);
            placedPlant = null;
            SendToFlutter.Send("error:The downloaded tree could not be displayed.");
            yield break;
        }

        RepairTransparentLeafMaterials(placedPlant);

        Vector3 importedScale = placedPlant.transform.localScale;
        Bounds importedBounds = CalculateBounds(placedPlant);
        float importedHeight = Mathf.Max(importedBounds.size.y, 0.001f);
        Vector3 matureScale = importedScale * (matureTreeHeightMeters / importedHeight);
        placedPlant.transform.localScale = matureScale * 0.03f;
        yield return AnimateScale(
            placedPlant.transform,
            placedPlant.transform.localScale,
            matureScale,
            growthAnimationSeconds);

        Bounds groundedBounds = CalculateBounds(placedPlant);
        placedPlant.transform.position += Vector3.up * (placementPose.position.y - groundedBounds.min.y);

        AddInteractionCollider(placedPlant);
        growthComplete = true;
        SendToFlutter.Send("growth_complete");
        SendToFlutter.Send("status:Walk around the tree and expand Information to learn more.");
    }

    private static void RepairTransparentLeafMaterials(GameObject modelRoot)
    {
        Shader transparentShader = Shader.Find("glTF/Unlit");
        if (transparentShader == null)
        {
            Debug.LogWarning("glTF/Unlit was not included in this build.");
            return;
        }

        foreach (Renderer modelRenderer in modelRoot.GetComponentsInChildren<Renderer>(true))
        {
            Material[] materials = modelRenderer.materials;
            bool changed = false;

            for (int index = 0; index < materials.Length; index++)
            {
                Material material = materials[index];
                if (material == null)
                    continue;

                string materialName = material.name.ToLowerInvariant();
                bool looksLikeLeaf =
                    materialName.Contains("leaf") ||
                    materialName.Contains("leaves") ||
                    materialName.Contains("foliage");
                bool isTransparent = material.renderQueue >= 3000;
                if (!looksLikeLeaf && !isTransparent)
                    continue;

                material.shader = transparentShader;
                material.SetFloat("_Mode", 2f);
                material.SetInt("_SrcBlend", (int)UnityEngine.Rendering.BlendMode.SrcAlpha);
                material.SetInt("_DstBlend", (int)UnityEngine.Rendering.BlendMode.OneMinusSrcAlpha);
                material.SetInt("_ZWrite", 0);
                material.SetInt("_CullMode", 0);
                material.EnableKeyword("_ALPHABLEND_ON");
                material.DisableKeyword("_ALPHATEST_ON");
                material.DisableKeyword("_ALPHAPREMULTIPLY_ON");
                material.SetOverrideTag("RenderType", "Transparent");
                material.renderQueue = 3000;
                changed = true;
            }

            if (changed)
                modelRenderer.materials = materials;
        }
    }

    private void ShowPlanes(bool visible)
    {
        if (planeManager == null)
            return;
        foreach (ARPlane plane in planeManager.trackables)
        {
            MeshRenderer renderer = plane.GetComponent<MeshRenderer>();
            if (renderer != null)
                renderer.enabled = visible;
        }
    }

    private IEnumerator LoadCachedModel()
    {
        SendToFlutter.Send("status:Preparing the downloaded tree…");
        selectedGltf?.Dispose();
        selectedGltf = new GltfImport();
        Task<bool> task = selectedGltf.LoadFile(selectedModelPath);
        while (!task.IsCompleted)
            yield return null;
        if (task.IsFaulted || !task.Result)
        {
            selectedGltf.Dispose();
            selectedGltf = null;
            modelReady = false;
            try
            {
                if (File.Exists(selectedModelPath))
                    File.Delete(selectedModelPath);
            }
            catch (Exception exception)
            {
                Debug.LogWarning($"Could not remove invalid GLB: {exception.Message}");
            }
            SendToFlutter.Send(
                "error:The downloaded model is invalid and was removed. Return to the shelf and download it again.");
            yield break;
        }

        modelReady = true;
        SendToFlutter.Send("model_downloaded");
        ReportModelReady();
    }

    private void ReportModelReady()
    {
        SendToFlutter.Send("model_ready");
        SendToFlutter.Send(
            ARSession.state == ARSessionState.SessionTracking
                ? "status:Move slowly to find a flat floor, then tap to place the sprout."
                : "status:Tree ready—waiting for AR tracking…");
    }

    private void ClearPlacedExperience()
    {
        if (placedPlant != null)
            Destroy(placedPlant);
        placedPlant = null;
        hasPlacement = false;
        watered = false;
        wateringCount = 0;
        growthStarted = false;
        growthComplete = false;
        shimmerSource.Stop();
    }

    private static void AddInteractionCollider(GameObject target)
    {
        if (target.GetComponentInChildren<Collider>() != null)
            return;
        Bounds bounds = CalculateBounds(target);
        BoxCollider collider = target.AddComponent<BoxCollider>();
        collider.center = target.transform.InverseTransformPoint(bounds.center);
        Vector3 scale = target.transform.lossyScale;
        collider.size = new Vector3(
            bounds.size.x / Mathf.Max(Mathf.Abs(scale.x), 0.0001f),
            bounds.size.y / Mathf.Max(Mathf.Abs(scale.y), 0.0001f),
            bounds.size.z / Mathf.Max(Mathf.Abs(scale.z), 0.0001f));
    }

    private static Bounds CalculateBounds(GameObject target)
    {
        Renderer[] renderers = target.GetComponentsInChildren<Renderer>();
        if (renderers.Length == 0)
            return new Bounds(target.transform.position, Vector3.one * 0.5f);
        Bounds bounds = renderers[0].bounds;
        for (int i = 1; i < renderers.Length; i++)
            bounds.Encapsulate(renderers[i].bounds);
        return bounds;
    }

    private void CreateWaterParticles(GameObject target)
    {
        Bounds bounds = CalculateBounds(target);
        GameObject water = new GameObject("WaterSplash");
        water.transform.position = bounds.center + Vector3.up * Mathf.Max(0.25f, bounds.extents.y);
        water.transform.rotation = Quaternion.LookRotation(Vector3.down);
        ParticleSystem particles = water.AddComponent<ParticleSystem>();
        var main = particles.main;
        main.duration = 0.7f;
        main.loop = false;
        main.startLifetime = 0.7f;
        main.startSpeed = 1.2f;
        main.startSize = 0.035f;
        main.startColor = new Color(0.25f, 0.7f, 1f, 0.9f);
        main.maxParticles = 70;
        var emission = particles.emission;
        emission.rateOverTime = 0f;
        emission.SetBursts(new[] { new ParticleSystem.Burst(0f, 45) });
        var shape = particles.shape;
        shape.shapeType = ParticleSystemShapeType.Cone;
        shape.angle = 18f;
        shape.radius = 0.12f;
        ParticleSystemRenderer renderer = water.GetComponent<ParticleSystemRenderer>();
        renderer.material = new Material(Shader.Find("Particles/Standard Unlit"));
        particles.Play();
        Destroy(water, 2f);
    }

    private IEnumerator PulseGlow(GameObject target)
    {
        Renderer[] renderers = target.GetComponentsInChildren<Renderer>();
        var colors = new List<(Material material, Color color)>();
        foreach (Renderer renderer in renderers)
        {
            foreach (Material material in renderer.materials)
            {
                if (!material.HasProperty("_EmissionColor"))
                    continue;
                material.EnableKeyword("_EMISSION");
                colors.Add((material, material.GetColor("_EmissionColor")));
            }
        }

        float duration = 1.4f;
        for (float elapsed = 0f; elapsed < duration; elapsed += Time.deltaTime)
        {
            float glow = Mathf.Sin(elapsed / duration * Mathf.PI) * 1.8f;
            foreach (var item in colors)
                item.material.SetColor("_EmissionColor", item.color + new Color(0.15f, 0.7f, 0.2f) * glow);
            yield return null;
        }
        foreach (var item in colors)
            item.material.SetColor("_EmissionColor", item.color);
    }

    private void CreateAudioExperience()
    {
        ambientSource = CreateAudioSource("ForestAmbience", false, true);
        effectSource = CreateAudioSource("PlantEffects", true, false);
        shimmerSource = CreateAudioSource("GrowthShimmer", true, true);
        ambientSource.clip = CreateAmbientClip();
        ambientSource.volume = 0f;
        ambientSource.Play();
        shimmerSource.clip = CreateShimmerClip();
        shimmerSource.volume = 0f;
        splashClip = CreateSplashClip();
        bloomClip = CreateBloomClip();
    }

    private AudioSource CreateAudioSource(string objectName, bool spatial, bool loop)
    {
        GameObject audioObject = new GameObject(objectName);
        audioObject.transform.SetParent(transform, false);
        AudioSource source = audioObject.AddComponent<AudioSource>();
        source.playOnAwake = false;
        source.loop = loop;
        source.spatialBlend = spatial ? 0.82f : 0f;
        source.rolloffMode = AudioRolloffMode.Linear;
        source.maxDistance = 12f;
        return source;
    }

    private void FadeAudio(AudioSource source, float target, float duration)
    {
        if (source != null)
            StartCoroutine(FadeAudioRoutine(source, target, duration));
    }

    private static IEnumerator FadeAudioRoutine(AudioSource source, float target, float duration)
    {
        if (target > 0f && !source.isPlaying)
            source.Play();
        float start = source.volume;
        for (float elapsed = 0f; elapsed < duration; elapsed += Time.deltaTime)
        {
            source.volume = Mathf.Lerp(start, target, elapsed / duration);
            yield return null;
        }
        source.volume = target;
        if (target <= 0f)
            source.Stop();
    }

    private static AudioClip CreateAmbientClip()
    {
        const int rate = 22050;
        float[] samples = new float[rate * 4];
        var random = new System.Random(4815);
        float filtered = 0f;
        for (int i = 0; i < samples.Length; i++)
        {
            float noise = (float)(random.NextDouble() * 2.0 - 1.0);
            filtered = Mathf.Lerp(filtered, noise, 0.015f);
            float breeze = filtered * 0.22f;
            float birds = (i % (rate * 2) < rate / 5)
                ? Mathf.Sin(i * 2f * Mathf.PI * 1450f / rate) * 0.025f
                : 0f;
            samples[i] = breeze + birds;
        }
        return CreateClip("Procedural Forest Ambience", samples, rate);
    }

    private static AudioClip CreateSplashClip()
    {
        const int rate = 22050;
        float[] samples = new float[(int)(rate * 0.8f)];
        var random = new System.Random(722);
        for (int i = 0; i < samples.Length; i++)
        {
            float t = i / (float)rate;
            float decay = Mathf.Exp(-5.5f * t);
            float noise = (float)(random.NextDouble() * 2.0 - 1.0) * decay;
            float drops = Mathf.Sin(2f * Mathf.PI * (420f - t * 180f) * t) * decay;
            samples[i] = noise * 0.45f + drops * 0.3f;
        }
        return CreateClip("Procedural Water Splash", samples, rate);
    }

    private static AudioClip CreateShimmerClip()
    {
        const int rate = 22050;
        float[] samples = new float[rate * 2];
        for (int i = 0; i < samples.Length; i++)
        {
            float t = i / (float)rate;
            float pulse = 0.55f + Mathf.Sin(t * Mathf.PI * 4f) * 0.2f;
            samples[i] = (
                Mathf.Sin(2f * Mathf.PI * 440f * t) * 0.18f +
                Mathf.Sin(2f * Mathf.PI * 660f * t) * 0.11f +
                Mathf.Sin(2f * Mathf.PI * 990f * t) * 0.06f) * pulse;
        }
        return CreateClip("Procedural Growth Shimmer", samples, rate);
    }

    private static AudioClip CreateBloomClip()
    {
        const int rate = 22050;
        float[] samples = new float[(int)(rate * 1.8f)];
        var random = new System.Random(991);
        float rustle = 0f;
        for (int i = 0; i < samples.Length; i++)
        {
            float t = i / (float)rate;
            float envelope = Mathf.Sin(Mathf.Clamp01(t / 1.8f) * Mathf.PI);
            rustle = Mathf.Lerp(rustle, (float)(random.NextDouble() * 2.0 - 1.0), 0.12f);
            float bloom = Mathf.Sin(2f * Mathf.PI * (260f + t * 180f) * t) * 0.25f;
            samples[i] = (rustle * 0.35f + bloom) * envelope;
        }
        return CreateClip("Procedural Foliage Bloom", samples, rate);
    }

    private static AudioClip CreateClip(string name, float[] samples, int sampleRate)
    {
        AudioClip clip = AudioClip.Create(name, samples.Length, 1, sampleRate, false);
        clip.SetData(samples, 0);
        return clip;
    }

    private static Material CreateGridMaterial()
    {
        Shader shader = Shader.Find("Unlit/Transparent");
        if (shader == null)
            shader = Shader.Find("Unlit/Color");
        Material material = new Material(shader);
        Texture2D texture = new Texture2D(64, 64, TextureFormat.RGBA32, false);
        texture.wrapMode = TextureWrapMode.Repeat;
        texture.filterMode = FilterMode.Bilinear;
        Color clear = new Color(0.1f, 0.55f, 0.25f, 0.08f);
        Color line = new Color(0.35f, 1f, 0.55f, 0.65f);
        for (int y = 0; y < 64; y++)
            for (int x = 0; x < 64; x++)
                texture.SetPixel(x, y, x < 2 || y < 2 ? line : clear);
        texture.Apply();
        material.mainTexture = texture;
        material.mainTextureScale = new Vector2(8f, 8f);
        material.color = Color.white;
        return material;
    }

    private static bool TryResolveLocalPath(string value, out string path)
    {
        path = value;
        if (string.IsNullOrWhiteSpace(value))
            return false;
        if (Uri.TryCreate(value, UriKind.Absolute, out Uri uri) && uri.IsFile)
            path = uri.LocalPath;
        return Path.IsPathRooted(path);
    }

    private static string GetCachedModelPath(string speciesID)
    {
        foreach (char invalid in Path.GetInvalidFileNameChars())
            speciesID = speciesID.Replace(invalid, '_');
        return Path.Combine(Application.persistentDataPath, "GreenAtlasModels", speciesID + ".glb");
    }

    private static IEnumerator AnimateScale(Transform target, Vector3 from, Vector3 to, float duration)
    {
        float elapsed = 0f;
        while (target != null && elapsed < duration)
        {
            elapsed += Time.deltaTime;
            float t = Mathf.SmoothStep(0f, 1f, Mathf.Clamp01(elapsed / duration));
            target.localScale = Vector3.LerpUnclamped(from, to, t);
            yield return null;
        }
        if (target != null)
            target.localScale = to;
    }
}

public sealed class PlaneGridTag : MonoBehaviour
{
}
