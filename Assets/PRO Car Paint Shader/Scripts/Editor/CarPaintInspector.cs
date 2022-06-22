using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEditor;
using UnityEngine;

public class CarPaintInspector : ShaderGUI
{
	MaterialProperty _Metallic;
	MaterialProperty _Smoothness;
	MaterialProperty _Emission;
	MaterialProperty _BlurDistance;
	MaterialProperty _PaintColor;
	MaterialProperty _SecondaryPaint;
	MaterialProperty _FresnelScale;
	MaterialProperty _FresnelPaintExponent;
	MaterialProperty _MatcapTexture;
	MaterialProperty _Albedo;
	MaterialProperty _AlbedoNormalScale;
	MaterialProperty _AlbedoNormal;
	MaterialProperty _Transparency;
	MaterialProperty _MetalSmoothnessB;
	MaterialProperty _FlakesNormal;
	MaterialProperty _FlakesMask;
	MaterialProperty _FlakesMetallic;
	MaterialProperty _FlakesSmoothness;
	MaterialProperty _FlakesSize;
	MaterialProperty _FlakesDistance;
	MaterialProperty _FlakesQuantity;
	MaterialProperty _FlakesColorOverride;
	MaterialProperty _ReflectionCubeMap;
	MaterialProperty _ReflectionColorOverride;
	MaterialProperty _ReflectionColor;
	MaterialProperty _ReflectionIntensity;
	MaterialProperty _ReflectionStrength;
	MaterialProperty _ReflectionExponent;
	MaterialProperty _ReflectionBlur;
	MaterialProperty _ClearCoatNormal;
	MaterialProperty _ClearCoatNormalScale;
	MaterialProperty _ClearCoatSmoothness;
	MaterialProperty _1Decal;
	MaterialProperty _2Decal;
	MaterialProperty _3Decal;
	MaterialProperty _4Decal;
	MaterialProperty _5Decal;
	MaterialProperty _1DecalColor;
	MaterialProperty _2DecalColor;
	MaterialProperty _3DecalColor;
	MaterialProperty _4DecalColor;
	MaterialProperty _5DecalColor;


	public enum ShaderType
	{
		Opaque,
		Transparent,
		Matcap
	}

	public enum ShaderModel
	{
		Three,
		Four
	}

	public enum DecalLayer
	{
		OverFlankLayer,
		UnderFlanksLayer
	}

	public enum ClearCoatLayer
	{
		OverDecalLayer,
		UnderDecalLayer
	}

	public enum TDecalLayer
	{
		OverClearcoat,
		UnderClearcoat
	}

	public enum QuickSetup
	{
		Select,
		Metallic,
		Gloss,
		Matte,
		Plastic,
		Pearlescent,
	}

	public QuickSetup quickSetup;
	public DecalLayer decalLayer;
	public ClearCoatLayer clearCoatLayer;
	public TDecalLayer tDecalLayer;
	public DecalLayer temp;

	private MaterialEditor matEditor;
	private MaterialProperty[] properties;
	private Material _material;
	private Shader shader;
	private Color originalGUIColor, clr;
	private ShaderModel shaderModel, lastshaderModel;
	private ShaderType shaderType, lastshaderType;

	private bool m_FirstTimeApply = true,
		BaseLayerFold, FlakesLayerFold, ClearCoatLayerFold, DecalsLayerFold,
		AlbedoUVFold, AlbedoNormalUVFold, MetalSmoothnessAOUVFold, ClearCoatNormalUVFold,
		Decal1UVfold, Decal2UVfold, Decal3UVfold, Decal4UVfold, Decal5UVfold,
		Flakes, REF, Decals;

	public Texture LOGO;
	public Rect iconRect;

	public override void OnGUI(MaterialEditor _materialEditor, MaterialProperty[] _properties)
	{
		EditorGUI.BeginChangeCheck();

		if (m_FirstTimeApply) {
			matEditor = _materialEditor;
			m_FirstTimeApply = false;
			originalGUIColor = GUI.backgroundColor;
			clr = new Color(.6f, .6f, .6f);
		}

		properties = _properties;
		_material = matEditor.target as Material;

		if (!matEditor.isVisible)
			return;

		find();

		LOGO = Resources.Load("CarPaintShader", typeof(Texture2D)) as Texture2D;
		iconRect.height = LOGO.height;
		iconRect.width = LOGO.width;
		GUILayout.BeginHorizontal();
		GUILayout.Space((EditorGUIUtility.currentViewWidth - LOGO.width - 10f) / 2f);
		GUILayout.Label(LOGO, GUILayout.Width(iconRect.width - 25f), GUILayout.Height(iconRect.height));
		GUILayout.EndHorizontal();

		EditorGUI.indentLevel++;

		GUILayout.BeginHorizontal();
		matEditor.DefaultPreviewSettingsGUI();
		GUILayout.EndHorizontal();
		matEditor.OnInteractivePreviewGUI(GUILayoutUtility.GetRect(200, 200), EditorGUIUtility.isProSkin ? EditorStyles.helpBox : EditorStyles.foldout);
		EditorGUILayout.Space();

		shaderType = (ShaderType)EditorGUILayout.EnumPopup("Shader Type", shaderType);
		if (shaderType != lastshaderType)
			ckeckchange();

		if (shaderType != ShaderType.Matcap) {
			shaderModel = (ShaderModel)EditorGUILayout.EnumPopup("Shader Model", shaderModel);
			if (shaderModel != lastshaderModel)
				ckeckchange();
		}

		if (shaderType == ShaderType.Opaque) {
			quickSetup = (QuickSetup)EditorGUILayout.EnumPopup("Quick Setup", quickSetup);
			if (quickSetup != QuickSetup.Select)
				quicksetup();
		}

		EditorGUILayout.Space();

		GUI.backgroundColor = EditorGUIUtility.isProSkin ?
            new Color(.65f, .65f, .65f) :
            new Color(.7f, .7f, .7f);
		EditorGUILayout.BeginVertical(GUI.skin.button);
		switch (shaderType) {
			case ShaderType.Opaque:
				RenderOpaque();
				break;
			case ShaderType.Transparent:
				RenderTransparent();
				break;
			case ShaderType.Matcap:
				RenderMatcap();
				break;
		}
		EditorGUILayout.EndVertical();
		ckeckchange();
	}

	void find()
	{
		shaderModel = (_material.shader.name.Contains("Lite")) ? ShaderModel.Three : ShaderModel.Four;
		shaderType = (_material.shader.name.Contains("Transparent")) ? ShaderType.Transparent :
            (_material.shader.name.Contains("Matcap")) ? ShaderType.Matcap :
            ShaderType.Opaque;

		_PaintColor = FindProperty("_Color", properties);

		_ReflectionCubeMap = FindProperty("_ReflectionCubeMap", properties);
		_ReflectionIntensity = FindProperty("_ReflectionIntensity", properties);
		_ReflectionStrength = FindProperty("_ReflectionStrength", properties);
		_ReflectionBlur = FindProperty("_ReflectionBlur", properties);
		_ReflectionExponent = FindProperty("_ReflectionExponent", properties);
		_ReflectionColor = FindProperty("_ReflectionColor", properties);
		_ReflectionColorOverride = FindProperty("_ReflectionColorOverride", properties);

		_Albedo = FindProperty("_MainTex", properties);

		switch (shaderType) {
			case ShaderType.Transparent:
				_Metallic = FindProperty("_Specular", properties);
				_Smoothness = FindProperty("_Glossiness", properties);
				_Transparency = FindProperty("_Cutoff", properties);
				_BlurDistance = FindProperty("_BlurDistance", properties);
				_Emission = FindProperty("_EmissionColor", properties);
				_AlbedoNormal = FindProperty("_BumpMap", properties);
				_AlbedoNormalScale = FindProperty("_BumpScale", properties);
				if (shaderModel == ShaderModel.Four)
					_MetalSmoothnessB = FindProperty("_SpecSmoothTrans", properties);
				break;
			case ShaderType.Matcap:
				_MatcapTexture = FindProperty("_MatcapTexture", properties);
				_SecondaryPaint = FindProperty("_SecondaryPaint", properties);
				_FresnelScale = FindProperty("_FresnelScale", properties);
				_FresnelPaintExponent = FindProperty("_FresnelPaintExponent", properties);
				break;
			case ShaderType.Opaque:
				_Metallic = FindProperty("_Metallic", properties);
				_Smoothness = FindProperty("_Glossiness", properties);
				_Emission = FindProperty("_EmissionColor", properties);
				_SecondaryPaint = FindProperty("_SecondaryPaint", properties);
				_FresnelScale = FindProperty("_FresnelScale", properties);
				_FresnelPaintExponent = FindProperty("_FresnelPaintExponent", properties);
				_AlbedoNormal = FindProperty("_BumpMap", properties);
				_AlbedoNormalScale = FindProperty("_BumpScale", properties);
				if (shaderModel == ShaderModel.Four)
					_MetalSmoothnessB = FindProperty("_MetallicGlossMap", properties);
				_FlakesNormal = FindProperty("_FlakesNormal", properties);
				_FlakesMask = FindProperty("_FlakesMask", properties);
				_FlakesMetallic = FindProperty("_FlakesMetallic", properties);
				_FlakesSmoothness = FindProperty("_FlakesSmoothness", properties);
				_FlakesSize = FindProperty("_FlakesSize", properties);
				_FlakesDistance = FindProperty("_FlakesDistance", properties);
				_FlakesQuantity = FindProperty("_FlakesQuantity", properties);
				_FlakesColorOverride = FindProperty("_FlakesColorOverride", properties);
				_ClearCoatNormal = FindProperty("_ClearCoatNormal", properties);
				_ClearCoatNormalScale = FindProperty("_ClearCoatNormalScale", properties);
				_ClearCoatSmoothness = FindProperty("_ClearCoatSmoothness", properties);
				break;
		}

		if (_material.IsKeywordEnabled("FLAKES"))
			Flakes = true;
		else
			Flakes = false;

		if (_material.IsKeywordEnabled("REF"))
			REF = true;
		else
			REF = false;

		decalLayer = (_material.IsKeywordEnabled("DECALS_Under")) ? DecalLayer.UnderFlanksLayer : DecalLayer.OverFlankLayer;
		clearCoatLayer = (_material.IsKeywordEnabled("REF_Under")) ? ClearCoatLayer.UnderDecalLayer : ClearCoatLayer.OverDecalLayer;
		 
		if (_material.IsKeywordEnabled("DECALS")) {
			Decals = true;
			_1Decal = FindProperty("_1Decal", properties);
			_1DecalColor = FindProperty("_1DecalColor", properties);
			_2Decal = FindProperty("_2Decal", properties);
			_2DecalColor = FindProperty("_2DecalColor", properties);
			if (shaderType == ShaderType.Matcap || shaderModel == ShaderModel.Four) {
				_3Decal = FindProperty("_3Decal", properties);
				_3DecalColor = FindProperty("_3DecalColor", properties);
				_4Decal = FindProperty("_4Decal", properties);
				_4DecalColor = FindProperty("_4DecalColor", properties);
				_5Decal = FindProperty("_5Decal", properties);
				_5DecalColor = FindProperty("_5DecalColor", properties);
			}
		} else {
			Decals = false;
		}
	}

	void RenderMatcap()
	{
		GUI.backgroundColor = originalGUIColor;
		EditorGUILayout.BeginHorizontal();
		if (GUILayout.Button(new GUIContent("Base\nLayer")))
			BaseLayerFold = resetSelect();
		GUI.backgroundColor = Decals ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("Decals\nLayer")))
			DecalsLayerFold = resetSelect();
		GUI.backgroundColor = REF ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("ClearCoat\nLayer")))
			ClearCoatLayerFold = resetSelect();
		EditorGUILayout.EndHorizontal();
		GUI.backgroundColor = originalGUIColor;

		if (BaseLayerFold) {
			EditorGUILayout.BeginVertical(GUI.skin.box);
			GUI.backgroundColor = clr;
			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Paints", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_PaintColor, "Paint (RGB)");
			matEditor.ShaderProperty(_SecondaryPaint, "Secoondary Paint (RGB)");
			matEditor.ShaderProperty(_FresnelScale, "Fresnel Scale");
			matEditor.ShaderProperty(_FresnelPaintExponent, "Fresnel Exponent");
			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Textures", MessageType.None);
			EditorGUILayout.Space();
			matEditor.TexturePropertySingleLine(new GUIContent("MatCap Texture"), _MatcapTexture);
			EditorGUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Albedo (RGB)  Paints  (A)"), _Albedo);
			AlbedoUVFold = EditorGUILayout.Foldout(AlbedoUVFold, "UV");
			EditorGUILayout.EndHorizontal();
			if (AlbedoUVFold) {
				matEditor.TextureScaleOffsetProperty(_Albedo);
			}

			GUI.backgroundColor = originalGUIColor;
			EditorGUILayout.EndVertical();
		}

		if (ClearCoatLayerFold) {
			clearcloatmenu();
		}

		if (DecalsLayerFold) {
			decalsMenu();
		}
	}

	void RenderTransparent()
	{
		GUI.backgroundColor = originalGUIColor;
		EditorGUILayout.BeginHorizontal();
		if (GUILayout.Button(new GUIContent("Base\nLayer")))
			BaseLayerFold = resetSelect();
		GUI.backgroundColor = Decals ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("Decals\nLayer")))
			DecalsLayerFold = resetSelect();
		GUI.backgroundColor = REF ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("ClearCoat\nLayer")))
			ClearCoatLayerFold = resetSelect();
		EditorGUILayout.EndHorizontal();
		GUI.backgroundColor = originalGUIColor;

		if (BaseLayerFold) {
			EditorGUILayout.BeginVertical(GUI.skin.box);
			GUI.backgroundColor = clr;
			EditorGUILayout.Space();
			EditorGUILayout.HelpBox("Properties", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_Metallic, "Specular");
			matEditor.ShaderProperty(_Smoothness, "Smoothness");
			matEditor.ShaderProperty(_Transparency, "Transparency");
			matEditor.ShaderProperty(_BlurDistance, "Blur Distance");

			if (_BlurDistance.floatValue != 0) {
				SetKeyword("BLUR", true);
			} else {
				SetKeyword("BLUR", false);
			}

			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Paints", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_PaintColor, "Paint (RGB)");
			matEditor.ShaderProperty(_Emission, "Emission (RGB)");
			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Textures", MessageType.None);
			EditorGUILayout.Space();
			EditorGUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Albedo (RGB)  Paint  (A)"), _Albedo);
			AlbedoUVFold = EditorGUILayout.Foldout(AlbedoUVFold, "UV");
			EditorGUILayout.EndHorizontal();
			if (AlbedoUVFold) {
				matEditor.TextureScaleOffsetProperty(_Albedo);
			}

			GUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Albedo Normal"), _AlbedoNormal, _AlbedoNormalScale);
			AlbedoNormalUVFold = EditorGUILayout.Foldout(AlbedoNormalUVFold, "UV");
			GUILayout.EndHorizontal();
			if (AlbedoNormalUVFold) {
				matEditor.TextureScaleOffsetProperty(_AlbedoNormal);
			}

			GUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Specular (R) Smoothness (G) Transparency (B)"), _MetalSmoothnessB);
			MetalSmoothnessAOUVFold = EditorGUILayout.Foldout(MetalSmoothnessAOUVFold, "UV");
			GUILayout.EndHorizontal();
			if (MetalSmoothnessAOUVFold) {
				matEditor.TextureScaleOffsetProperty(_MetalSmoothnessB);
			}
			GUI.backgroundColor = originalGUIColor;
			EditorGUILayout.EndVertical();
		}

		if (ClearCoatLayerFold) {
			clearcloatmenu();
		}

		if (DecalsLayerFold) {
			decalsMenu();
		}
	}

	void RenderOpaque()
	{
		GUI.backgroundColor = originalGUIColor;
		EditorGUILayout.BeginHorizontal();
		if (GUILayout.Button(new GUIContent("Base\nLayer")))
			BaseLayerFold = resetSelect();
		GUI.backgroundColor = Flakes ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("Flakes\nLayer")))
			FlakesLayerFold = resetSelect();
		GUI.backgroundColor = Decals ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("Decals\nLayer")))
			DecalsLayerFold = resetSelect();
		GUI.backgroundColor = REF ? !EditorGUIUtility.isProSkin ? Color.white : Color.gray : EditorGUIUtility.isProSkin ? Color.white : Color.gray;
		if (GUILayout.Button(new GUIContent("ClearCoat\nLayer")))
			ClearCoatLayerFold = resetSelect();
		EditorGUILayout.EndHorizontal();
		GUI.backgroundColor = originalGUIColor;

		if (BaseLayerFold) {
			EditorGUILayout.BeginVertical(GUI.skin.box);
			GUI.backgroundColor = clr;
			EditorGUILayout.Space();
			EditorGUILayout.HelpBox("Properties", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_Metallic, "Metallic");
			matEditor.ShaderProperty(_Smoothness, "Smoothness");
			matEditor.ShaderProperty(_Emission, "Emission (RGB)");
			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Paints", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_PaintColor, "Paint (RGB)");
			matEditor.ShaderProperty(_SecondaryPaint, "Secoondary Paint (RGB)");
			matEditor.ShaderProperty(_FresnelScale, "Fresnel Scale");
			matEditor.ShaderProperty(_FresnelPaintExponent, "Fresnel Exponent");
			EditorGUILayout.Space();

			EditorGUILayout.HelpBox("Textures", MessageType.None);
			EditorGUILayout.Space();
			EditorGUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Albedo (RGB)  Paints  (A)"), _Albedo);
			AlbedoUVFold = EditorGUILayout.Foldout(AlbedoUVFold, "UV");
			EditorGUILayout.EndHorizontal();
			if (AlbedoUVFold) {
				matEditor.TextureScaleOffsetProperty(_Albedo);
			}

			GUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Albedo Normal"), _AlbedoNormal, _AlbedoNormalScale);
			AlbedoNormalUVFold = EditorGUILayout.Foldout(AlbedoNormalUVFold, "UV");
			GUILayout.EndHorizontal();
			if (AlbedoNormalUVFold) {
				matEditor.TextureScaleOffsetProperty(_AlbedoNormal);
			}

			if (shaderModel == ShaderModel.Four) {
				GUILayout.BeginHorizontal();
				matEditor.TexturePropertySingleLine(new GUIContent("Metallic (R) Smoothness (G) Emission (B)"), _MetalSmoothnessB);
				MetalSmoothnessAOUVFold = EditorGUILayout.Foldout(MetalSmoothnessAOUVFold, "UV");
				GUILayout.EndHorizontal();
				if (MetalSmoothnessAOUVFold) {
					matEditor.TextureScaleOffsetProperty(_MetalSmoothnessB);
				}
			}
			GUI.backgroundColor = originalGUIColor;
			EditorGUILayout.EndVertical();
		}

		if (FlakesLayerFold) {
			EditorGUILayout.BeginVertical(GUI.skin.box);
			GUI.backgroundColor = clr;
			EditorGUILayout.Space();
			Flakes = EditorGUILayout.Toggle("Enable", Flakes);
			SetKeyword("FLAKES", Flakes);

			EditorGUILayout.Space();
			EditorGUILayout.HelpBox("Textures", MessageType.None);
			EditorGUILayout.Space();

			matEditor.TexturePropertySingleLine(new GUIContent("Flakes Color (RGB) Mask (A)"), _FlakesMask);
			matEditor.TexturePropertySingleLine(new GUIContent("Flakes Normal"), _FlakesNormal, _FlakesQuantity);

			EditorGUILayout.Space();
			EditorGUILayout.HelpBox("Properties", MessageType.None);
			EditorGUILayout.Space();
			matEditor.ShaderProperty(_FlakesMetallic, "Metallic");
			matEditor.ShaderProperty(_FlakesSmoothness, "Smoothness");
			EditorGUILayout.BeginHorizontal();
			_FlakesSize.floatValue = EditorGUILayout.FloatField("Size - Distance", _FlakesSize.floatValue);
			_FlakesDistance.floatValue = Mathf.Clamp(EditorGUILayout.FloatField(_FlakesDistance.floatValue), 0, 20);
			EditorGUILayout.EndHorizontal();
			matEditor.ShaderProperty(_FlakesColorOverride, "Color Override");
			GUI.backgroundColor = originalGUIColor;
			EditorGUILayout.EndVertical();
		}

		if (DecalsLayerFold) {
			decalsMenu();
		}

		if (ClearCoatLayerFold) {
			clearcloatmenu();
		}
	}

	void decalsMenu()
	{
		EditorGUILayout.BeginVertical(GUI.skin.box);
		GUI.backgroundColor = clr;
		EditorGUILayout.Space();
		Decals = EditorGUILayout.Toggle("Enable", Decals);
		SetKeyword("DECALS", Decals);
		EditorGUILayout.Space();

		if (Decals) {
			if (shaderType == ShaderType.Opaque && Flakes) {
				decalLayer = (DecalLayer)EditorGUILayout.EnumPopup("Decals Layer", decalLayer);
				SetKeyword("DECALS_Under", (decalLayer == DecalLayer.UnderFlanksLayer) ? true : false);
				EditorGUILayout.Space();
			}

			EditorGUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("1 decal"), _1Decal);
			Decal1UVfold = EditorGUILayout.Foldout(Decal1UVfold, "UV");
			GUILayout.EndHorizontal();
			if (Decal1UVfold) {
				matEditor.TextureScaleOffsetProperty(_1Decal);
			}
			matEditor.ShaderProperty(_1DecalColor, "", 0);

			EditorGUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("2 decal"), _2Decal);
			Decal2UVfold = EditorGUILayout.Foldout(Decal2UVfold, "UV");
			GUILayout.EndHorizontal();
			if (Decal2UVfold) {
				matEditor.TextureScaleOffsetProperty(_2Decal);
			}
			matEditor.ShaderProperty(_2DecalColor, "", 0);

			if (shaderType == ShaderType.Matcap || shaderModel == ShaderModel.Four) {
				EditorGUILayout.BeginHorizontal();
				matEditor.TexturePropertySingleLine(new GUIContent("3 decal"), _3Decal);
				Decal3UVfold = EditorGUILayout.Foldout(Decal3UVfold, "UV");
				GUILayout.EndHorizontal();
				if (Decal3UVfold) {
					matEditor.TextureScaleOffsetProperty(_3Decal);
				}
				matEditor.ShaderProperty(_3DecalColor, "", 0);

				EditorGUILayout.BeginHorizontal();
				matEditor.TexturePropertySingleLine(new GUIContent("4 decal"), _4Decal);
				Decal4UVfold = EditorGUILayout.Foldout(Decal4UVfold, "UV");
				GUILayout.EndHorizontal();
				if (Decal4UVfold) {
					matEditor.TextureScaleOffsetProperty(_4Decal);
				}
				matEditor.ShaderProperty(_4DecalColor, "", 0);

				EditorGUILayout.BeginHorizontal();
				matEditor.TexturePropertySingleLine(new GUIContent("5 decal"), _5Decal);
				Decal5UVfold = EditorGUILayout.Foldout(Decal5UVfold, "UV");
				GUILayout.EndHorizontal();
				if (Decal5UVfold) {
					matEditor.TextureScaleOffsetProperty(_5Decal);
				}
				matEditor.ShaderProperty(_5DecalColor, "", 0);
			}
		}
		GUI.backgroundColor = originalGUIColor;
		EditorGUILayout.EndVertical();
	}

	void clearcloatmenu()
	{
		EditorGUILayout.BeginVertical(GUI.skin.box);
		GUI.backgroundColor = clr;
		EditorGUILayout.Space();

		REF = EditorGUILayout.Toggle("Enable", REF);
		SetKeyword("REF", REF);
		EditorGUILayout.Space();

		if (Decals) {
			clearCoatLayer = (ClearCoatLayer)EditorGUILayout.EnumPopup("ClearCoat Layer", clearCoatLayer);
			SetKeyword("REF_Under", (clearCoatLayer == ClearCoatLayer.UnderDecalLayer) ? true : false);
		} else if (Flakes) {
			temp = (clearCoatLayer == ClearCoatLayer.UnderDecalLayer) ? DecalLayer.UnderFlanksLayer : DecalLayer.OverFlankLayer;
			temp = (DecalLayer)EditorGUILayout.EnumPopup("ClearCoat Layer", temp);
			clearCoatLayer = (temp == DecalLayer.UnderFlanksLayer) ? ClearCoatLayer.UnderDecalLayer : ClearCoatLayer.OverDecalLayer;
			SetKeyword("REF_Under", (clearCoatLayer == ClearCoatLayer.UnderDecalLayer) ? true : false);
		}

		EditorGUILayout.Space();
		EditorGUILayout.HelpBox("Textures", MessageType.None);
		EditorGUILayout.Space();
		matEditor.TexturePropertySingleLine(new GUIContent("Reflection Cubemap"), _ReflectionCubeMap);

		if (shaderType == ShaderType.Opaque) {
			GUILayout.BeginHorizontal();
			matEditor.TexturePropertySingleLine(new GUIContent("Clear Coat Normal"), _ClearCoatNormal, _ClearCoatNormalScale);
			ClearCoatNormalUVFold = EditorGUILayout.Foldout(ClearCoatNormalUVFold, "UV");
			GUILayout.EndHorizontal();
			if (ClearCoatNormalUVFold) {
				matEditor.TextureScaleOffsetProperty(_ClearCoatNormal);
			}
		}

		EditorGUILayout.HelpBox("Properties", MessageType.None);
		EditorGUILayout.Space();
		if (shaderType == ShaderType.Opaque) {
			matEditor.ShaderProperty(_ClearCoatSmoothness, "Clear Coat Smoothness");
		}
		EditorGUILayout.BeginHorizontal();
		_ReflectionIntensity.floatValue = Mathf.Clamp(EditorGUILayout.FloatField("Intensity - Strength", _ReflectionIntensity.floatValue), 0, 10);
		_ReflectionStrength.floatValue = Mathf.Clamp(EditorGUILayout.FloatField(_ReflectionStrength.floatValue), 0, 1);
		EditorGUILayout.EndHorizontal();
		EditorGUILayout.BeginHorizontal();
		_ReflectionExponent.floatValue = Mathf.Clamp(EditorGUILayout.FloatField("Exponent - Blur", _ReflectionExponent.floatValue), -1, 10);
		_ReflectionBlur.floatValue = Mathf.Clamp(EditorGUILayout.FloatField(_ReflectionBlur.floatValue), 0, 10);
		EditorGUILayout.EndHorizontal();
		matEditor.ShaderProperty(_ReflectionColorOverride, "Reflection Color Override");
		if (_ReflectionColorOverride.floatValue == 1)
			matEditor.ShaderProperty(_ReflectionColor, "Reflection Color (RGB)");
		GUI.backgroundColor = originalGUIColor;
		EditorGUILayout.EndVertical();
	}


	bool resetSelect()
	{
		BaseLayerFold = false;
		FlakesLayerFold = false;
		DecalsLayerFold = false;
		ClearCoatLayerFold = false;
		return true;
	}

	void SetKeyword(string keyword, bool state)
	{
		if (state)
			_material.EnableKeyword(keyword);
		else
			_material.DisableKeyword(keyword);
	}

	void ckeckchange()
	{
		if (shaderType != lastshaderType || lastshaderModel != shaderModel) {
			switch (shaderType) {
				case ShaderType.Transparent:
					shader = Shader.Find((shaderModel == ShaderModel.Four) ? "Hidden / Pro Car Paint Transparent Shader" : "Hidden / Pro Car Paint Transparent Shader - Lite");
					_material.shader = shader;
					break;
				case ShaderType.Opaque:
					shader = Shader.Find((shaderModel == ShaderModel.Four) ? "Pro Car Paint Shader" : "Hidden / Pro Car Paint Shader - Lite");
					_material.shader = shader;
					break;
				case ShaderType.Matcap:
					shader = Shader.Find("Hidden / Pro Car Paint Matcap Shader");
					_material.shader = shader;
					break;
			}
			lastshaderType = shaderType;
			lastshaderModel = shaderModel;
			matEditor.Repaint();
		}
	}

	void quicksetup()
	{
		switch (quickSetup) {
			case QuickSetup.Metallic:
				_ReflectionIntensity.floatValue = 1f;
				_Metallic.floatValue = 0.75f;
				_Smoothness.floatValue = 0.5f;
				_FresnelScale.floatValue = 0f;
				_ReflectionIntensity.floatValue = 1f;
				_ReflectionBlur.floatValue = 0.5f;
				break;
			case QuickSetup.Gloss:
				_Metallic.floatValue = 0.5f;
				_Smoothness.floatValue = 0.5f;
				_FresnelScale.floatValue = 0f;
				_ReflectionIntensity.floatValue = 0.5f;
				_ReflectionBlur.floatValue = 1f;
				break;
			case QuickSetup.Matte:
				_Metallic.floatValue = 0.5f;
				_Smoothness.floatValue = 0.25f;
				_FresnelScale.floatValue = 0f;
				_ReflectionIntensity.floatValue = 0.5f;
				_ReflectionBlur.floatValue = 2f;
				break;
			case QuickSetup.Plastic:
				_Metallic.floatValue = 0.0f;
				_Smoothness.floatValue = 0.25f;
				_FresnelScale.floatValue = 0f;
				_ReflectionIntensity.floatValue = 0.1f;
				_ReflectionBlur.floatValue = 5f;
				break;
			case QuickSetup.Pearlescent:
				_Metallic.floatValue = 0.5f;
				_Smoothness.floatValue = 0.5f;
				_FresnelScale.floatValue = 1f;
				_ReflectionIntensity.floatValue = 0.2f;
				_ReflectionBlur.floatValue = 1f;
				break;
		}
		quickSetup = QuickSetup.Select;
	}
}