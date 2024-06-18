using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;
using Newtonsoft.Json;
using TMPro;
using System.Threading.Tasks;
using ResourcePlugin;
public class PluginHelper : MonoBehaviour
{
    [SerializeField] private Button btnStart, btnStop;
    [SerializeField] private TextMeshProUGUI txtInfo;
    [SerializeField] private string trackedData;
    [SerializeField] private TraceUIElement uiElememntPrefab;
    [SerializeField] private List<SystemTrace> systemTraces;
    [SerializeField] private List<TraceUIElement> traceUIElements;
    [SerializeField] private Transform taceElementsparent;

    void Start()
    {
#if UNITY_IOS
        ResourceUsage.Instance.Init();
        btnStart.interactable = true;
        btnStop.interactable = false;
#else
        btnStart.interactable = false;
        btnStop.interactable = false;
#endif
#if UNITY_EDITOR
        ConvertDummyData();
#endif
    }

    public void StartTracking()
    {
#if UNITY_IOS
        btnStart.interactable = false;
        btnStop.interactable = true;
        ResourceUsage.Instance.StartTracking();  // Calling ResourceUsage Start Track
        txtInfo.text = "Tracking Started.";
#endif

    }
    public void StopTracking()
    {
#if UNITY_IOS
        systemTraces = ResourceUsage.Instance.StopTracking(); // Calling ResourceUsage Stop Track & Handle Response
        if (systemTraces != null)
        {
            Debug.Log("Data Count : "+systemTraces.Count);
            txtInfo.text = "Data Count : "+systemTraces.Count;
            DisplayTrace();
        }
        else
        {
            Debug.Log("Data not Come from Native");
            txtInfo.text = "No Data to Display";
        }
        btnStart.interactable = true;
        btnStop.interactable = false;
#endif
    }
    [ContextMenu("ConvertDummyData")]
    public void ConvertDummyData()
    {
        systemTraces = new List<SystemTrace>();
        Debug.Log(trackedData);
         systemTraces = JsonConvert.DeserializeObject<List<SystemTrace>>(trackedData);
        if (trackedData != null)
        {
            txtInfo.text = "";
            DisplayTrace();
        }
        else
        {
            txtInfo.text = "No Data to Display";
        }
    }

    void DisplayTrace()
    {
        if (systemTraces == null || systemTraces.Count == 0)
        {
            foreach (var item in traceUIElements)
            {
                item.Parent.SetActive(false);
            }
        }
        else
        {
            int MinCount = 0;
            if (traceUIElements.Count > systemTraces.Count)
            {
                MinCount = systemTraces.Count;
            }
            else
            {
                MinCount = traceUIElements.Count;
            }

            int i = 0;
            for (; i < MinCount; i++)
            {
                SetData(traceUIElements[i],systemTraces[i]);
            }

            for (; i < systemTraces.Count; i++)
            {

                TraceUIElement traceUI = Instantiate(uiElememntPrefab, taceElementsparent) as TraceUIElement;
                traceUIElements.Add(traceUI);
                SetData(traceUIElements[i], systemTraces[i]);

            }
            for (; i < traceUIElements.Count; i++)
            {
                traceUIElements[i].Parent.SetActive(false);
            }
        }
    }
    async void SetData(TraceUIElement traceUI, SystemTrace systemTrace)
    {
        traceUI.Parent.SetActive(true);
        traceUI.txtTime.text = systemTrace.timestamp;

        traceUI.txtCpuUsage.text = string.Format("Ideal : {0}\nUser : {1}\nNice : {2}\nSystem : {3}", systemTrace.cpuUsage.idle.ToString("0.00"), systemTrace.cpuUsage.user.ToString("0.00"), systemTrace.cpuUsage.nice.ToString("0.00"), systemTrace.cpuUsage.system.ToString("0.00"));

        traceUI.txtGpuUsage.text = string.Format("Allocated : {0}\nMax : {1}",systemTrace.gpuUsage.allocated,systemTrace.gpuUsage.max);

        traceUI.txtRamUsage.text = string.Format("Free : {0}\nWired : {1}\nActive : {2}\nCompressed : {3}\nInactive :{4}",
            systemTrace.ramUsage.free.ToString("0.00"), systemTrace.ramUsage.wired.ToString("0.00"), systemTrace.ramUsage.active.ToString("0.00"), systemTrace.ramUsage.compressed.ToString("0.00"), systemTrace.ramUsage.inactive.ToString("0.00"));

        LayoutRebuilder.ForceRebuildLayoutImmediate(traceUI.GetComponent<RectTransform>());
        await Task.Delay(100);
        LayoutRebuilder.ForceRebuildLayoutImmediate(traceUI.transform.parent.GetComponent<RectTransform>());
    }

}


