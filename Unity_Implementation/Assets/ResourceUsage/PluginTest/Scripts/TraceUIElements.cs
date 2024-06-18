using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using TMPro;

[System.Serializable]
public class TraceUIElement : MonoBehaviour
{
    public GameObject Parent;
    public TextMeshProUGUI txtTime;
    public TextMeshProUGUI txtCpuUsage;
    public TextMeshProUGUI txtRamUsage;
    public TextMeshProUGUI txtGpuUsage;
}
