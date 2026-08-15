using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using GLTFast;
using UnityEngine;
using UnityEngine.InputSystem.EnhancedTouch;
using UnityEngine.Networking;
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
    [SerializeField, Min(0.5f)] private float growthDistanceMeters = 2f;
    [SerializeField, Min(0.1f)] private float growthAnimationSeconds = 2.2f;

    private static readonly List<ARRaycastHit> Hits = new();
    private GameObject selectedPrefab;
    private GltfImport selectedGltf;
    private string selectedSpeciesID;
    private string selectedRemoteUrl;
    private string selectedModelPath;
    private bool modelReady;
    private bool isDownloading;
    private GameObject placedPlant;
    private Pose placementPose;
    private bool hasPlacement;
    private bool watered;
    private bool growthStarted;
    private bool growthComplete;
    private bool reportedReady;
    private int lastDistanceDecimeter = -1;
    private Vector3 sproutBaseScale;
    private Camera arCamera;
    private Material planeGridMaterial;
    private AudioSource ambientSource;
    private AudioSource effectSource;
    private AudioSource shimmerSource;
    private AudioClip splashClip;
    private AudioClip bloomClip;
    private readonly List<GameObject> informationPins = new();

    private void Awake()
    {
        if (raycastManager == null)
            raycastManager = FindFirstObjectByType<ARRaycastManager>();
        if (planeManager == null)
            planeManager = FindFirstObjectByType<ARPlaneManager>();
        arCamera = Camera.main;
        CreateAudioExperience();
        planeGridMaterial = CreateGridMaterial();
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
        if (planeGridMaterial != null)
            Destroy(planeGridMaterial);
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
            EnsurePlaneGridVisuals();

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
        if (!Physics.Raycast(ray, out RaycastHit hit, 100f))
            return;

        InfoNodeMarker marker = hit.collider.GetComponent<InfoNodeMarker>();
        if (marker != null)
        {
            effectSource.PlayOneShot(CreatePinClip(), 0.35f);
            SendToFlutter.Send($"info_node:{marker.key}");
            return;
        }

        if (!watered && placedPlant != null && hit.transform.IsChildOf(placedPlant.transform))
            NurtureSprout();
    }

    public void LoadSelectedSpecies(string payload)
    {
        string[] parts = payload.Split(new[] { '|' }, 2);
        string speciesID = parts[0];
        string location = parts.Length > 1 ? parts[1] : string.Empty;
        SpeciesEntry match = species.Find(entry => string.Equals(
            entry.speciesID, speciesID, StringComparison.OrdinalIgnoreCase));

        ClearPlacedExperience();
        selectedGltf?.Dispose();
        selectedGltf = null;
        selectedPrefab = match != null ? match.prefab : null;
        selectedSpeciesID = speciesID;
        selectedRemoteUrl = string.Empty;
        selectedModelPath = string.Empty;
        modelReady = selectedPrefab != null;

        if (modelReady)
        {
            ReportModelReady();
            return;
        }

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

        if (Uri.TryCreate(location, UriKind.Absolute, out Uri uri) &&
            (uri.Scheme == Uri.UriSchemeHttps || uri.Scheme == Uri.UriSchemeHttp))
        {
            selectedRemoteUrl = location;
            SendToFlutter.Send($"model_download_required:{speciesID}");
            return;
        }

        SendToFlutter.Send($"error:The downloaded AR model for {speciesID} was not found.");
    }

    public void DownloadSelectedSpecies(string ignored)
    {
        if (!modelReady && !isDownloading && !string.IsNullOrWhiteSpace(selectedRemoteUrl))
            StartCoroutine(DownloadModel());
    }

    public void WaterPlant(string ignored)
    {
        NurtureSprout();
    }

    public void ResetPlant(string ignored)
    {
        ClearPlacedExperience();
        ShowPlanes(true);
        SendToFlutter.Send("status:Scan the surface grid, then tap to place the sprout.");
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
        SendToFlutter.Send("growth:0/1");
        SendToFlutter.Send("status:Sprout anchored—tap the sprout to water it.");
    }

    private void NurtureSprout()
    {
        if (!hasPlacement || placedPlant == null || watered || growthComplete)
            return;

        watered = true;
        lastDistanceDecimeter = -1;
        CreateWaterParticles(placedPlant);
        effectSource.PlayOneShot(splashClip, 0.9f);
        StartCoroutine(PulseGlow(placedPlant));
        shimmerSource.volume = 0.04f;
        shimmerSource.pitch = 0.75f;
        if (!shimmerSource.isPlaying)
            shimmerSource.Play();
        SendToFlutter.Send("growth:1/1");
        SendToFlutter.Send("status:Water absorbed—step backward and listen as it gathers strength.");
    }

    private void UpdateProximityGrowth()
    {
        if (arCamera == null)
            arCamera = Camera.main;
        if (arCamera == null)
            return;

        float distance = Vector3.Distance(arCamera.transform.position, placementPose.position);
        float progress = Mathf.Clamp01(distance / growthDistanceMeters);
        shimmerSource.volume = Mathf.Lerp(0.04f, 0.5f, progress);
        shimmerSource.pitch = Mathf.Lerp(0.75f, 1.65f, progress);
        int decimeter = Mathf.FloorToInt(Mathf.Min(distance, growthDistanceMeters) * 10f);
        if (decimeter != lastDistanceDecimeter)
        {
            lastDistanceDecimeter = decimeter;
            SendToFlutter.Send($"growth_distance:{Mathf.Min(distance, growthDistanceMeters):0.0}");
        }

        if (distance >= growthDistanceMeters)
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
        if (selectedPrefab != null)
        {
            placedPlant = Instantiate(selectedPrefab, placementPose.position, placementPose.rotation, transform);
        }
        else
        {
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
        }

        Vector3 matureScale = placedPlant.transform.localScale;
        placedPlant.transform.localScale = matureScale * 0.03f;
        yield return AnimateScale(
            placedPlant.transform,
            placedPlant.transform.localScale,
            matureScale,
            growthAnimationSeconds);

        AddInteractionCollider(placedPlant);
        CreateInformationPins(placedPlant);
        growthComplete = true;
        SendToFlutter.Send("growth_complete");
        SendToFlutter.Send("status:Walk around the tree and tap its floating information pins.");
    }

    private void CreateInformationPins(GameObject tree)
    {
        Bounds bounds = CalculateBounds(tree);
        float side = Mathf.Max(0.35f, bounds.extents.x * 0.65f);
        CreateInformationPin("leaves", new Vector3(
            bounds.center.x + side, bounds.min.y + bounds.size.y * 0.74f, bounds.center.z),
            new Color(0.35f, 0.9f, 0.42f));
        CreateInformationPin("bark", new Vector3(
            bounds.center.x + Mathf.Min(side, 0.65f), bounds.min.y + bounds.size.y * 0.33f, bounds.center.z),
            new Color(0.95f, 0.62f, 0.25f));
        CreateInformationPin("conservation", new Vector3(
            bounds.center.x - Mathf.Min(side, 0.8f), bounds.min.y + Mathf.Max(0.35f, bounds.size.y * 0.1f), bounds.center.z),
            new Color(0.3f, 0.72f, 1f));
    }

    private void CreateInformationPin(string key, Vector3 worldPosition, Color color)
    {
        GameObject pin = GameObject.CreatePrimitive(PrimitiveType.Sphere);
        pin.name = $"InfoPin_{key}";
        pin.transform.SetParent(transform, true);
        pin.transform.position = worldPosition;
        pin.transform.localScale = Vector3.one * 0.18f;
        Renderer renderer = pin.GetComponent<Renderer>();
        Material material = new Material(Shader.Find("Unlit/Color"));
        material.color = color;
        renderer.material = material;
        pin.AddComponent<InfoNodeMarker>().key = key;
        pin.AddComponent<MarkerPulse>();
        informationPins.Add(pin);
    }

    private void EnsurePlaneGridVisuals()
    {
        if (planeManager == null || planeGridMaterial == null || hasPlacement)
            return;
        foreach (ARPlane plane in planeManager.trackables)
        {
            if (plane.GetComponent<PlaneGridTag>() != null)
                continue;
            MeshFilter filter = plane.GetComponent<MeshFilter>() ?? plane.gameObject.AddComponent<MeshFilter>();
            MeshRenderer renderer = plane.GetComponent<MeshRenderer>() ?? plane.gameObject.AddComponent<MeshRenderer>();
            if (plane.GetComponent<ARPlaneMeshVisualizer>() == null)
                plane.gameObject.AddComponent<ARPlaneMeshVisualizer>();
            renderer.sharedMaterial = planeGridMaterial;
            plane.gameObject.AddComponent<PlaneGridTag>();
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

    private IEnumerator DownloadModel()
    {
        isDownloading = true;
        Directory.CreateDirectory(Path.GetDirectoryName(selectedModelPath));
        string temporaryPath = selectedModelPath + ".download";
        if (File.Exists(temporaryPath))
            File.Delete(temporaryPath);

        using UnityWebRequest request = UnityWebRequest.Get(selectedRemoteUrl);
        request.downloadHandler = new DownloadHandlerFile(temporaryPath);
        UnityWebRequestAsyncOperation operation = request.SendWebRequest();
        int lastPercent = -1;
        while (!operation.isDone)
        {
            int percent = Mathf.Clamp(Mathf.RoundToInt(request.downloadProgress * 100f), 0, 99);
            if (percent != lastPercent)
            {
                lastPercent = percent;
                SendToFlutter.Send($"model_download_progress:{percent}");
            }
            yield return null;
        }

        isDownloading = false;
        if (request.result != UnityWebRequest.Result.Success)
        {
            if (File.Exists(temporaryPath))
                File.Delete(temporaryPath);
            SendToFlutter.Send($"error:Model download failed: {request.error}");
            yield break;
        }

        if (File.Exists(selectedModelPath))
            File.Delete(selectedModelPath);
        File.Move(temporaryPath, selectedModelPath);
        SendToFlutter.Send("model_download_progress:100");
        yield return LoadCachedModel();
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
            SendToFlutter.Send("error:The downloaded model is invalid. Delete it and try again.");
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
                ? "status:Scan the surface grid, then tap to place the sprout."
                : "status:Tree ready—waiting for AR tracking…");
    }

    private void ClearPlacedExperience()
    {
        if (placedPlant != null)
            Destroy(placedPlant);
        foreach (GameObject pin in informationPins)
            if (pin != null)
                Destroy(pin);
        informationPins.Clear();
        placedPlant = null;
        hasPlacement = false;
        watered = false;
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

    private static AudioClip CreatePinClip()
    {
        const int rate = 22050;
        float[] samples = new float[(int)(rate * 0.18f)];
        for (int i = 0; i < samples.Length; i++)
        {
            float t = i / (float)rate;
            samples[i] = Mathf.Sin(2f * Mathf.PI * 880f * t) * Mathf.Exp(-18f * t) * 0.35f;
        }
        return CreateClip("Information Pin", samples, rate);
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

public sealed class InfoNodeMarker : MonoBehaviour
{
    public string key;
}

public sealed class MarkerPulse : MonoBehaviour
{
    private Vector3 baseScale;
    private void Awake() => baseScale = transform.localScale;
    private void Update() => transform.localScale = baseScale * (1f + Mathf.Sin(Time.time * 3f) * 0.12f);
}

public sealed class PlaneGridTag : MonoBehaviour
{
}
