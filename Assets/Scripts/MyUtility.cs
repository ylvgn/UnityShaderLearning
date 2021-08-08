using System.Collections;
using System.Collections.Generic;
#if UNITY_EDITOR
using UnityEngine;
#endif

public class MyUtility
{

#if UNITY_EDITOR
    // world-space(scene view)
    public static void LogPoint(Vector3 pos, string text, Color fontColor, int fontSize = 30)
    {
        var oldColor = GUI.color;
        var oldFontSize = GUI.skin.label.fontSize;
        UnityEditor.Handles.BeginGUI();
        GUI.color = fontColor;
        var view = UnityEditor.SceneView.currentDrawingSceneView;
        Vector3 screenPos = view.camera.WorldToScreenPoint(pos);
        GUI.skin.label.fontSize = fontSize;
        Vector2 size = GUI.skin.label.CalcSize(new GUIContent(text));
        GUI.Label(new Rect(screenPos.x - 120, view.camera.pixelHeight - screenPos.y - 100, size.x, size.y), text);
        UnityEditor.Handles.EndGUI();
        GUI.color = oldColor;
        GUI.skin.label.fontSize = oldFontSize;
    }

    // screen-space(scene view)
    public static void LogPoint(Rect printRect, string text, Color fontColor, int fontSize = 40)
    {
        var oldColor = GUI.color;
        var oldFontSize = GUI.skin.label.fontSize;
        UnityEditor.Handles.BeginGUI();
        GUI.color = fontColor;
        GUI.skin.label.fontSize = fontSize;
        Vector2 size = GUI.skin.label.CalcSize(new GUIContent(text));
        printRect.width += size.x;
        printRect.height += size.y;
        GUI.Label(printRect, text);
        UnityEditor.Handles.EndGUI();
        GUI.color = oldColor;
        GUI.skin.label.fontSize = oldFontSize;
    }
#endif
}
