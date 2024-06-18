using System.Runtime.InteropServices;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using Newtonsoft.Json;
namespace ResourcePlugin
{
    public class ResourceUsage : MonoBehaviour
    {
        // Creating Singleton 
        private static ResourceUsage instance;
        public static ResourceUsage Instance
        {
            get
            {
                if (instance == null)
                {
                    GameObject o = new GameObject("ResourceUsage");
                    instance = o.AddComponent<ResourceUsage>();
                    DontDestroyOnLoad(o);
                }
                return instance;
            }
        }
        //Local Datalist
        private List<SystemTrace> systemTraces;
        //Local Store Response
        private string nativeResponse;
        //Create for Instance Check
        public static bool IsInit;
        public void Init()
        {
            if (!IsInit)
            {
                IsInit = true;
            }
        }
        //Calling Native Plugin
#if UNITY_IOS
        [DllImport("__Internal")]
        private static extern void startTracking();

        [DllImport("__Internal")]
        private static extern string stopTracking();
#endif
        // Local Function to call Native Plugin
        public void StartTracking()
        {
            startTracking();
        }

        // Local Function to call Native Plugin and return data
        public List<SystemTrace> StopTracking()
        {
            systemTraces = new List<SystemTrace>();
            nativeResponse = stopTracking();
            if (nativeResponse != null)
            {
                systemTraces = JsonConvert.DeserializeObject<List<SystemTrace>>(nativeResponse);
                Debug.Log("Data Count : " + systemTraces.Count);
            }
            else
            {
                Debug.Log("Data not Come from Native");
            }
            return systemTraces;
        }

    }
    [System.Serializable]
    public class CpuUsage
    {
        public double idle;
        public double user;
        public int nice;
        public int system;
    }
    [System.Serializable]
    public class GpuUsage
    {
        public int allocated;
        public int max;
    }
    [System.Serializable]
    public class RamUsage
    {
        public double free;
        public double wired;
        public double active;
        public double compressed;
        public double inactive;
    }
    [System.Serializable]
    public class SystemTrace
    {
        public CpuUsage cpuUsage;
        public RamUsage ramUsage;
        public GpuUsage gpuUsage;
        public string timestamp;
    }
}