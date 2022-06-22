Shader "Hidden / Pro Car Paint Shader - Lite"
{
	Properties
	{
		_Metallic("Base Metallic",Range(0,1))= 0
		_Glossiness("Base Smoothness",Range(0,1))= 0
		[HDR]_EmissionColor("Emission(RGB)",Color)= (0,0,0,0)
		[HDR]_Color("Paint(RGB)",Color)= (0.5,0.5,0.5,1)
		[HDR]_SecondaryPaint("Secoondary Paint(RGB)",Color)= (0,0,0,1)
		_FresnelScale("Fresnel Scale",Range(0,1))= 0
		_FresnelPaintExponent("Fresnel Paint Exponent",Range(0,10))= 1
		_MainTex("Albedo(RGB)Paints(A)",2D)= "black" {}
		[Normal]_BumpMap("Albedo Normal",2D)= "bump" {}
		_BumpScale("Albedo Normal Map Scale",Float)= 1
		_FlakesMask("Flakes Color(RGB)Mask(A)",2D)= "black" {}
		[Normal]_FlakesNormal("Flakes Normal",2D)= "bump" {}
		_FlakesMetallic("Flakes Metallic",Range(0,1))= 0.8
		_FlakesSmoothness("Flakes Smoothness",Range(0,1))= 0.5
		_FlakesSize("Flakes Size",Float)= 1
		_FlakesQuantity("Flakes Quantity",Range(0,10))= 1
		_FlakesDistance("Flakes Distance",Range(0,20))= 3
		[Toggle]_FlakesColorOverride("Flakes Color Override",Float)= 0
		_ReflectionCubeMap("Reflection CubeMap",CUBE)= "black" {}
		_ReflectionIntensity("Reflection Intensity",Range(0,10))= 0.75
		_ReflectionStrength("Reflection Strength",Range(0,1))= 0.2
		_ReflectionExponent("Reflection Power",Range(0,10))= 0.5
		_ReflectionBlur("Reflection Blur",Range(0,8))= 1
		[Toggle]_ReflectionColorOverride("Reflection ColorOverride",Float)= 1
		[HDR]_ReflectionColor("Reflection Color",Color)= (1,1,1,1)
		_ClearCoatSmoothness("Clear Coat Smoothness",Range(0,1))= 1
		[Normal]_ClearCoatNormal("Clear Coat Normal",2D)= "bump" {}
		_ClearCoatNormalScale("Clear Coat Normal Scale",Float)= 1
		_1Decal("1 Decal",2D)= "black" {}
		[HDR]_1DecalColor("1 Decal Color",Color)= (1,0.5,0,1)
		_2Decal("2 Decal",2D)= "black" {}
		[HDR]_2DecalColor("2 Decal Color",Color)= (1,0.5,0,1)
		[HideInInspector][PerRendererData][NoScaleOffset] _("",2D)= "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry" "IsEmissive" = "true"  }
		LOD 200
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityStandardUtils.cginc"
		#include "Lighting.cginc"

		#pragma target 3.0
		#pragma multi_compile	 FLAKES_OFF 	FLAKES
		#pragma multi_compile	 REF_OFF 		REF
		#pragma multi_compile 	 DECALS_OFF 	DECALS
		#pragma multi_compile 	 DECALS_Over 	DECALS_Under
		#pragma multi_compile 	 REF_Over 		REF_Under

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal)reflect(data.worldRefl,half3(dot(data.internalSurfaceTtoW0,normal),dot(data.internalSurfaceTtoW1,normal),dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal)fixed3(dot(data.internalSurfaceTtoW0,normal),dot(data.internalSurfaceTtoW1,normal),dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
			float2 uv_;
			float2 texcoord_0;
			float eyeDepth;
			float3 worldRefl;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			fixed3 Albedo;
			fixed3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			fixed Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform float4 _SecondaryPaint;
		uniform float4 _Color;
		uniform float _FresnelScale;
		uniform float _FresnelPaintExponent;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform float _FlakesColorOverride;
		uniform sampler2D _FlakesMask;
		uniform float _FlakesSize;
		uniform float _FlakesDistance;
		uniform float _FlakesQuantity;
		uniform float _ReflectionColorOverride;
		uniform float4 _ReflectionColor;
		uniform samplerCUBE _ReflectionCubeMap;
		uniform fixed _ReflectionBlur;
		uniform float _ReflectionIntensity;
		uniform float _ReflectionExponent;
		uniform float _ReflectionStrength;
		uniform float4 _1DecalColor;
		uniform sampler2D _1Decal;
		uniform float4 _1Decal_ST;
		uniform float4 _2DecalColor;
		uniform sampler2D _2Decal;
		uniform float4 _2Decal_ST;
		uniform float _BumpScale;
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform sampler2D _FlakesNormal;
		uniform float4 _EmissionColor;
		uniform float _Metallic;
		uniform float _FlakesMetallic;
		uniform float _Glossiness;
		uniform float _FlakesSmoothness;
		uniform float _ClearCoatNormalScale;
		uniform sampler2D _ClearCoatNormal;
		uniform float4 _ClearCoatNormal_ST;
		uniform float _ClearCoatSmoothness;

		float3 HSVToRGB(float3 result)
		{
			float4 K = float4(1.0,2.0 / 3.0,1.0 / 3.0,3.0);
			float3 p = abs(frac(result.xxx + K.xyz)* 6.0 - K.www);
			return result.z * lerp(K.xxx,clamp(p - K.xxx,0.0,1.0),result.y);
		}

		float3 RGBToHSV(float3 result)
		{
			float4 K = float4(0.0,-1.0 / 3.0,2.0 / 3.0,-1.0);
			float4 p = lerp(float4(result.bg,K.wz),float4(result.gb,K.xy),step(result.b,result.g));
			float4 q = lerp(float4(p.xyw,result.r),float4(result.r,p.yzx),step(p.x,result.r));
			float d = q.x - min(q.w,q.y);
			float e = 1.0e-10;
			return float3(abs(q.z + (q.w - q.y)/ (6.0 * d + e)),d / (q.x + e),q.x);
		}

		void vertexDataFunc(inout appdata_full v,out Input o)
		{
			UNITY_INITIALIZE_OUTPUT(Input,o);
			o.eyeDepth = -UnityObjectToViewPos(v.vertex.xyz).z;
			o.texcoord_0.xy = v.texcoord.xy * (_FlakesSize).xx + float2(0,0);
		}

		inline half4 LightingStandardCustomLighting(inout SurfaceOutputCustomLightingCustom s,half3 viewDir,UnityGI gi)
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 Final = 0;
			SurfaceOutputStandard s1359 = (SurfaceOutputStandard)0;
			float3 _worldPos = i.worldPos;
			fixed3 _worldViewDir = normalize(UnityWorldSpaceViewDir(_worldPos));
			float3 _worldNormal = WorldNormalVector(i,float3(0,0,1));
			float2 uv_BumpMap = i.uv_ * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float3 Bump = UnpackScaleNormal(tex2D(_BumpMap,uv_BumpMap),_BumpScale);
			float fresnel357 = (_FresnelScale * pow(1.0 - dot(_worldNormal,_worldViewDir),_FresnelPaintExponent));
			float4 lerp251 = lerp(_SecondaryPaint,_Color,(1.0 - fresnel357));
			float2 uv_MainTex = i.uv_ * _MainTex_ST.xy + _MainTex_ST.zw;
			float4 tex2D148 = tex2D(_MainTex,uv_MainTex);
			float4 lerp331 = lerp(lerp251,tex2D148,tex2D148.a);
			#ifdef FLAKES
			float cameraDepthFade881 = ((i.eyeDepth -_ProjectionParams.y - 0.0)/ _FlakesDistance);
			float CamDepth914 = (1.0 - saturate(cameraDepthFade881));
			float3 hsvTorgb920 = RGBToHSV(lerp331.rgb);
			float3 hsvTorgb919 = HSVToRGB(float3(hsvTorgb920.x,hsvTorgb920.y,(hsvTorgb920.z * 1.25)));
			float4 tex2D1447 = tex2D(_FlakesMask,i.texcoord_0);
			float FlakesMask1368 = saturate(CamDepth914 * tex2D1447.a * ceil(_FlakesQuantity));
			#endif
			#ifdef REF
			float3 hsvTorgb480 = RGBToHSV(lerp331.rgb);
			float clamp482 = clamp((hsvTorgb480.z + 0.15),0.15,(float)1);
			float3 hsvTorgb481 = HSVToRGB(float3(hsvTorgb480.x,hsvTorgb480.y,clamp482));
			float3 _worldReflection = WorldReflectionVector(i,float3(0,0,1));
			float fresnel1320 = (0.0 + _ReflectionIntensity * pow(1.0 - dot(_worldNormal,_worldViewDir),_ReflectionExponent));
			float4 Reflection324 = lerp(float4(hsvTorgb481,0.0),_ReflectionColor,_ReflectionColorOverride)* texCUBElod(_ReflectionCubeMap,float4(_worldReflection,_ReflectionBlur))* fresnel1320 ;
			float Fer = (0.0 + (_ReflectionStrength + _ReflectionStrength)* pow(1.0 - dot(_worldNormal,_worldViewDir),_ReflectionExponent / 2.5));
			float ref_fres = saturate(_ReflectionStrength * Fer);
			#endif
			#ifdef FLAKES
			#ifdef DECALS
			#ifdef DECALS_Under
			#ifdef REF
			#ifdef REF_Under
			float4 BF = lerp((lerp331 + Reflection324),Reflection324,ref_fres);
			#else
			float4 BF = lerp331;
			#endif
			#else
			float4 BF = lerp331;
			#endif
			#else
			#ifdef REF
			#ifdef REF_Under
			float4 temp  = lerp(lerp331,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			float4 BF = lerp((temp + Reflection324),Reflection324,ref_fres);
			#else
			float4 BF = lerp(lerp331,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#endif
			#else
			float4 BF = lerp(lerp331,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#endif
			#endif
			#else
			#ifdef REF
			#ifdef REF_Under
			float4 temp = lerp((lerp331 + Reflection324),Reflection324,ref_fres);
			float4 BF = lerp(temp,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#else
			float4 temp  = lerp(lerp331,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			float4 BF = lerp((temp + Reflection324),Reflection324,ref_fres);
			#endif
			#else
			float4 BF = lerp(lerp331,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#endif
			#endif
			#else
			#ifdef DECALS
			#ifdef REF
			#ifdef REF_Under
			float4 BF = lerp((lerp331 + Reflection324),Reflection324,ref_fres);
			#else
			float4 BF = lerp331;
			#endif
			#else
			float4 BF = lerp331;
			#endif
			#else
			#ifdef REF
			float4 BF = lerp((lerp331 + Reflection324),Reflection324,ref_fres);
			#else
			float4 BF = lerp331;
			#endif
			#endif
			#endif
			#ifndef DECALS
			float4 Decals618 = BF;
			#else
			float2 uv_1Decal = i.uv_ * _1Decal_ST.xy + _1Decal_ST.zw;
			float4 tex2D238 = tex2D(_1Decal,uv_1Decal);
			float4 lerp417 = lerp(BF,(_1DecalColor * tex2D238),tex2D238.a);
			float2 uv_2Decal = i.uv_ * _2Decal_ST.xy + _2Decal_ST.zw;
			float4 tex2D1589 = tex2D(_2Decal,uv_2Decal);
			float4 lerp418 = lerp(lerp417,(_2DecalColor * tex2D1589),tex2D1589.a);
			float DecalsMask1627 = saturate(tex2D238.a + tex2D1589.a);
			float4 Decals618 = lerp418;
			#endif
			#ifdef FLAKES
			#ifdef DECALS
			#ifdef DECALS_Under
			float lerp1518 = lerp(_Metallic,_FlakesMetallic,FlakesMask1368);
			float lerp1524 = lerp(_Glossiness,_FlakesSmoothness,FlakesMask1368);
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368));
			#ifdef REF
			#ifdef REF_Under
			float4 Done = lerp(Decals618,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#else
			float4 temp = lerp((Decals618 + Reflection324),Reflection324,ref_fres);
			float4 Done = lerp(temp,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#endif
			#else
			float4 Done = lerp(Decals618,(lerp(float4(hsvTorgb919,0.0),tex2D1447,_FlakesColorOverride)),FlakesMask1368);
			#endif
			#else
			float lerp1518 = lerp(_Metallic,_FlakesMetallic,saturate(FlakesMask1368  - DecalsMask1627));
			float lerp1524 = lerp(_Glossiness,_FlakesSmoothness,saturate(FlakesMask1368  - DecalsMask1627));
			#ifdef REF
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368 - (DecalsMask1627 + ref_fres)));
			#ifdef REF_Under
			float4 Done = Decals618;
			#else
			float4 Done = lerp((Decals618 + Reflection324),Reflection324,ref_fres);
			#endif
			#else
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368 - DecalsMask1627));
			float4 Done = Decals618;
			#endif
			#endif
			#else
			float lerp1518 = lerp(_Metallic,_FlakesMetallic,FlakesMask1368);
			float lerp1524 = lerp(_Glossiness,_FlakesSmoothness,FlakesMask1368);
			float4 Done = BF;
			#ifdef REF
			#ifdef REF_Under
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368));
			#else
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368 -  float3(ref_fres,ref_fres,ref_fres)));
			#endif
			#else
			float3 lerp1528 = lerp(Bump,UnpackScaleNormal(tex2D(_FlakesNormal,i.texcoord_0),_FlakesQuantity),saturate(FlakesMask1368));
			#endif
			#endif
			#else
			float3 lerp1528 = Bump;
			float lerp1518 = _Metallic;
			float lerp1524 = _Glossiness;
			#ifdef DECALS
			#ifdef REF
			#ifdef REF_Under
			float4 Done = Decals618;
			#else
			float4 Done = lerp((Decals618 + Reflection324),Reflection324,ref_fres);
			#endif
			#else
			float4 Done = Decals618;
			#endif
			#else
			float4 Done = BF;
			#endif
			#endif
			s1359.Albedo = Done;
			s1359.Normal = WorldNormalVector(i,lerp1528);
			s1359.Emission = _EmissionColor.rgb;
			s1359.Metallic = lerp1518;
			s1359.Smoothness = lerp1524;
			s1359.Occlusion = 1.0;
			gi.light.ndotl = LambertTerm(s1359.Normal,gi.light.dir);
			data.light = gi.light;
			UnityGI gi1359 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g1359;
			g1359.roughness = 1 - s1359.Smoothness;
			g1359.reflUVW = reflect(-data.worldViewDir,s1359.Normal);
			gi1359 = UnityGlobalIllumination(data,s1359.Occlusion,s1359.Normal,g1359);
			#endif
			float3 surf1359 = LightingStandard(s1359,viewDir,gi1359).rgb;
			surf1359 += s1359.Emission;
			#ifdef REF
			SurfaceOutputStandardSpecular s1455 = (SurfaceOutputStandardSpecular)0;
			s1455.Albedo = float3(0,0,0);
			float2 uv_ClearCoatNormal = i.uv_ * _ClearCoatNormal_ST.xy + _ClearCoatNormal_ST.zw;
			s1455.Normal = WorldNormalVector(i,UnpackScaleNormal(tex2D(_ClearCoatNormal,uv_ClearCoatNormal),_ClearCoatNormalScale));
			s1455.Emission = float3(0,0,0);
			s1455.Specular = 1;
			s1455.Smoothness =  _ClearCoatSmoothness;
			s1455.Occlusion = 1.0;
			gi.light.ndotl = LambertTerm(s1455.Normal,gi.light.dir);
			data.light = gi.light;
			UnityGI gi1455 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g1455;
			g1455.roughness = 1 - s1455.Smoothness;
			g1455.reflUVW = reflect(-data.worldViewDir,s1455.Normal);
			gi1455 = UnityGlobalIllumination(data,s1455.Occlusion,s1455.Normal,g1455);
			#endif
			float3 surf1455 = LightingStandardSpecular(s1455,viewDir,gi1455).rgb;
			surf1455 += s1455.Emission;
			float fresnel1467 = (0.05 + 1.0 * pow(1.0 - dot(_worldNormal,_worldViewDir),5.0));
			Final.rgb = lerp(surf1359,surf1455,fresnel1467);
			#else
			Final.rgb = surf1359;
			#endif
			Final.a = 1;
			return Final;
		}

		inline void LightingStandardCustomLighting_GI(inout SurfaceOutputCustomLightingCustom s,UnityGIInput data,inout UnityGI gi)
		{
			s.GIData = data;
		}

		void surf(Input i,inout SurfaceOutputCustomLightingCustom o)
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows vertex:vertexDataFunc

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			# include "HLSLSupport.cginc"
			#if(SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN)
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 tSpace0 : TEXCOORD1;
				float4 tSpace1 : TEXCOORD2;
				float4 tSpace2 : TEXCOORD3;
				float4 texcoords01 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			v2f vert(appdata_full v)
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_OUTPUT(v2f,o);
				UNITY_TRANSFER_INSTANCE_ID(v,o);
				Input customInputData;
				vertexDataFunc(v,customInputData);
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				fixed3 worldBinormal = cross(worldNormal,worldTangent)* tangentSign;
				o.tSpace0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.tSpace1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.tSpace2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
				o.texcoords01 = float4(v.texcoord.xy,v.texcoord1.xy);
				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
				return o;
			}
			fixed4 frag(v2f IN
			#if !defined(CAN_SKIP_VPOS)
			,UNITY_VPOS_TYPE vpos : VPOS
			#endif
			): SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT(Input,surfIN);
				surfIN.uv_.xy = IN.texcoords01.xy;
				float3 worldPos = float3(IN.tSpace0.w,IN.tSpace1.w,IN.tSpace2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3(IN.tSpace0.z,IN.tSpace1.z,IN.tSpace2.z);
				surfIN.worldRefl = -worldViewDir;
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT(SurfaceOutputCustomLightingCustom,o)
				surf(surfIN,o);
				#if defined(CAN_SKIP_VPOS)
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
	}
	Fallback "Standard"
	CustomEditor "CarPaintInspector"
}