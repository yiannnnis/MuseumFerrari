Shader "Hidden / Pro Car Paint Transparent Shader"
{
	Properties
	{
		_Specular("Specular",Range(0,1))= 0.2
		_Glossiness("Smoothness",Range(0,1))= 0.9
		_Cutoff("Transparency",Range(0,1))= 0.5
		_BlurDistance("BLUR Distance",Range(0,0.1))= 0
		[HDR]_Color("Paint Color",Color)= (1,0,0,1)
		[HDR]_EmissionColor("Emission",Color)= (0,0,0,0)
		_BumpScale("BumNormalp Scale",Float)= 1
		_SpecSmoothTrans("Specular (R)Smoothness (G)Transparency (B)",2D)= "white" {}
		_MainTex("Albedo",2D)= "black" {}
		_ReflectionCubeMap("Reflection CubeMap",CUBE)= "black" {}
		[Normal]_BumpMap("Normal",2D)= "bump" {}
		_ReflectionIntensity("Reflection Intensity",Range(0,10))= 0.75
		_ReflectionStrength("Reflection Strength",Range(0,1))= 0.2
		_ReflectionExponent("Reflection Exponent",Range(0,10))= 0.75
		_ReflectionBlur("Reflection BLUR",Range(0,8))= 4
		[Toggle]_ReflectionColorOverride("Reflection ColorOverride",Float)= 1
		[HDR]_ReflectionColor("Reflection Color",Color)= (1,1,1,0)
		_1Decal("1 Decal",2D)= "black" {}
		[HDR]_1DecalColor("1 Decal Color",Color)= (1,0.5,0,1)
		_2Decal("2 Decal",2D)= "black" {}
		[HDR]_2DecalColor("2 Decal Color",Color)= (1,0.5,0,1)
		_3Decal("3 Decal",2D)= "black" {}
		[HDR]_3DecalColor("3 Decal Color",Color)= (1,0.5,0,1)
		_4Decal("4 Decal",2D)= "black" {}
		[HDR]_4DecalColor("4 Decal Color",Color)= (1,0.5,0,1)
		_5Decal("5 Decal",2D)= "black" {}
		[HDR]_5DecalColor("5 Decal Color",Color)= (1,0.5,0,1)
		[HideInInspector][PerRendererData][NoScaleOffset] _("",2D)= "white" {}
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Transparent" "IgnoreProjector" = "True" "IsEmissive" = "true"  }
		LOD 200
		Cull Back
		GrabPass{ }
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityStandardUtils.cginc"
		#include "Lighting.cginc"

		#pragma target 4.0
		#pragma multi_compile	 BLUR_OFF       BLUR
		#pragma multi_compile	 REF_OFF 		REF
		#pragma multi_compile 	 DECALS_OFF 	DECALS
		#pragma multi_compile 	 REF_Over 		REF_Under

		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal)reflect (data.worldRefl,half3(dot(data.internalSurfaceTtoW0,normal),dot(data.internalSurfaceTtoW1,normal),dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal)fixed3(dot(data.internalSurfaceTtoW0,normal),dot(data.internalSurfaceTtoW1,normal),dot(data.internalSurfaceTtoW2,normal))
		#endif

		struct Input
		{
			float4 screenPos;
			float3 worldNormal;
			INTERNAL_DATA
			float2 uv_;
			float3 worldRefl;
			float3 worldPos;
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

		uniform sampler2D _GrabTexture;
		uniform float _BlurDistance;
		uniform float4 _Color;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
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
		uniform float4 _3DecalColor;
		uniform sampler2D _3Decal;
		uniform float4 _3Decal_ST;
		uniform float4 _4DecalColor;
		uniform sampler2D _4Decal;
		uniform float4 _4Decal_ST;
		uniform float4 _5DecalColor;
		uniform sampler2D _5Decal;
		uniform float4 _5Decal_ST;
		uniform float _BumpScale;
		uniform sampler2D _BumpMap;
		uniform float4 _BumpMap_ST;
		uniform float4 _EmissionColor;
		uniform float _Specular;
		uniform sampler2D _SpecSmoothTrans;
		uniform float4 _SpecSmoothTrans_ST;
		uniform float _Glossiness;
		uniform float _Cutoff;

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

		inline half4 LightingStandardCustomLighting(inout SurfaceOutputCustomLightingCustom s,half3 viewDir,UnityGI gi)
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 Final = 0;
			SurfaceOutputStandardSpecular s1265 = (SurfaceOutputStandardSpecular)0;
			float2 uv_SpecSmoothTrans = i.uv_ * _SpecSmoothTrans_ST.xy + _SpecSmoothTrans_ST.zw;
			float4 tex2D605 = tex2D(_SpecSmoothTrans,uv_SpecSmoothTrans);
			float2 uv_MainTex = i.uv_ * _MainTex_ST.xy + _MainTex_ST.zw;
			float4 tex2D1218 = tex2D(_MainTex,uv_MainTex);
			float2 uv_BumpMap = i.uv_ * _BumpMap_ST.xy + _BumpMap_ST.zw;
			float4 lerpResult1219 = lerp(_Color,tex2D1218,tex2D1218.a);
			#ifdef REF
			float3 hsvTorgb1191 = RGBToHSV(lerpResult1219.rgb);
			float clampResult1194 = clamp((hsvTorgb1191.z + 0.15),0.15,(float)255);
			float3 hsvTorgb1195 = HSVToRGB(float3(hsvTorgb1191.x,hsvTorgb1191.y,clampResult1194));
			float3 _worldReflection = WorldReflectionVector(i,float3(0,0,1));
			float3 _worldPos = i.worldPos;
			fixed3 _worldViewDir = normalize(UnityWorldSpaceViewDir(_worldPos));
			float3 _worldNormal = WorldNormalVector(i,float3(0,0,1));
			float fresnel1203 = (0.0 + _ReflectionIntensity * pow(1.0 - dot(_worldNormal,_worldViewDir),_ReflectionExponent));
			float4 Reflection324 = (lerp(float4(hsvTorgb1195,0.0),_ReflectionColor,_ReflectionColorOverride)* texCUBElod(_ReflectionCubeMap,float4(_worldReflection,_ReflectionBlur))* fresnel1203);
			float Fer = (0.0 + (_ReflectionStrength + _ReflectionStrength)* pow(1.0 - dot(_worldNormal,_worldViewDir),_ReflectionExponent / 2.5));
			float ref_fres = saturate(_ReflectionStrength * Fer);
			#ifdef REF_Under
			float4 Base1187 = lerp((lerpResult1219 + Reflection324),Reflection324,ref_fres);
			#else
			float4 Base1187 = lerpResult1219;
			#endif
			#else
			float4 Base1187 = lerpResult1219;
			#endif
			#ifndef DECALS
			float4 Decals618 = Base1187;
			#else
			float2 uv_1Decal = i.uv_ * _1Decal_ST.xy + _1Decal_ST.zw;
			float4 tex2D238 = tex2D(_1Decal,uv_1Decal);
			float4 One_926 = lerp(Base1187,(_1DecalColor * tex2D238),tex2D238.a);
			float2 uv_2Decal = i.uv_ * _2Decal_ST.xy + _2Decal_ST.zw;
			float4 tex2D1333 = tex2D(_2Decal,uv_2Decal);
			float4 Two_927 = lerp(One_926,(_2DecalColor * tex2D1333),tex2D1333.a);
			float2 uv_3Decal = i.uv_ * _3Decal_ST.xy + _3Decal_ST.zw;
			float4 tex2D1348 = tex2D(_3Decal,uv_3Decal);
			float4 Three_928 = lerp(Two_927,(_3DecalColor * tex2D1348),tex2D1348.a);
			float2 uv_4Decal = i.uv_ * _4Decal_ST.xy + _4Decal_ST.zw;
			float4 tex2D1338 = tex2D(_4Decal,uv_4Decal);
			float4 Four_929 = lerp(Three_928,(_4DecalColor * tex2D1338),tex2D1338.a);
			float2 uv_5Decal = i.uv_ * _5Decal_ST.xy + _5Decal_ST.zw;
			float4 tex2D1343 = tex2D(_5Decal,uv_5Decal);
			float4 Five_930 = lerp(Four_929,(_5DecalColor * tex2D1343),tex2D1343.a);
			float4 Decals618 = Five_930;
			#endif
			#ifdef REF
			#ifdef REF_Under
			s1265.Albedo = Decals618.rgb;
			#else
			s1265.Albedo = lerp((Decals618 + Reflection324),Reflection324,ref_fres);
			#endif
			#else
			s1265.Albedo = Decals618.rgb;
			#endif
			s1265.Normal = WorldNormalVector(i,UnpackScaleNormal(tex2D(_BumpMap,uv_BumpMap),_BumpScale));
			s1265.Emission = _EmissionColor.rgb;
			s1265.Specular = ((_Specular * tex2D605.r)).xxx;
			s1265.Smoothness = (tex2D605.g * _Glossiness);
			s1265.Occlusion = 1.0;
			gi.light.ndotl = LambertTerm(s1265.Normal,gi.light.dir);
			data.light = gi.light;
			UnityGI gi1265 = gi;
			#ifdef UNITY_PASS_FORWARDBASE
			Unity_GlossyEnvironmentData g1265;
			g1265.roughness = 1 - s1265.Smoothness;
			g1265.reflUVW = reflect(-data.worldViewDir,s1265.Normal);
			gi1265 = UnityGlobalIllumination(data,s1265.Occlusion,s1265.Normal,g1265);
			#endif
			float3 surfResult1265 = LightingStandardSpecular (s1265,viewDir,gi1265).rgb;
			surfResult1265 += s1265.Emission;
			float4 screenPos = float4(i.screenPos.xyz,i.screenPos.w + 0.00000000001);
			float4 screenPosNorm = screenPos / screenPos.w;
			screenPosNorm.z = (UNITY_NEAR_CLIP_VALUE >= 0)? screenPosNorm.z : screenPosNorm.z * 0.5 + 0.5;
			float4 screenColor1285 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD(screenPosNorm));
			float output_1269_0 = distance(unity_WorldTransformParams,float4(_WorldSpaceCameraPos,0.0));
			float myVarName01271 = (_BlurDistance / (output_1269_0 / log10(output_1269_0)));
			float2 appendResult1282 = (float2(0.0,myVarName01271));
			float4 screenColor1295 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm + float4(appendResult1282,0.0,0.0))));
			#ifdef BLUR
			float2 appendResult1276 = (float2(myVarName01271,0.0));
			float4 screenColor1293 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm + float4(appendResult1276,0.0,0.0))));
			float2 appendResult1280 = (float2(myVarName01271,myVarName01271));
			float4 screenColor1300 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm + float4(appendResult1280,0.0,0.0))));
			float2 appendResult1279 = (float2(myVarName01271,-myVarName01271));
			float4 screenColor1299 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm - float4(appendResult1279,0.0,0.0))));
			float2 appendResult1281 = (float2(0.0,myVarName01271));
			float4 screenColor1296 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm - float4(appendResult1281,0.0,0.0))));
			float2 appendResult1278 = (float2(myVarName01271,0.0));
			float4 screenColor1297 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm - float4(appendResult1278,0.0,0.0))));
			float2 appendResult1277 = (float2(myVarName01271,myVarName01271));
			float4 screenColor1294 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((screenPosNorm - float4(appendResult1277,0.0,0.0))));
			float2 appendResult1275 = (float2(-myVarName01271,myVarName01271));
			float4 screenColor1298 = tex2Dproj(_GrabTexture,UNITY_PROJ_COORD((float4(appendResult1275,0.0,0.0)- screenPosNorm)));
			Final.rgb  = lerp(((screenColor1285 + screenColor1295 + screenColor1293 + screenColor1300 + screenColor1299 + screenColor1296 + screenColor1297 + screenColor1294 + screenColor1298)/ 9.0),float4(surfResult1265,0.0),lerp(1.0,(1.0 - _Cutoff),(tex2D605.b * tex2D605.a)));
			#else
			Final.rgb  = lerp(screenColor1285,float4(surfResult1265,0.0),lerp(1.0,(1.0 - _Cutoff),(tex2D605.b * tex2D605.a)));
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
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows

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
			#if (SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN)
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 screenPos : TEXCOORD7;
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
				o.screenPos = ComputeScreenPos(o.pos);
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
				surfIN.screenPos = IN.screenPos;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT(SurfaceOutputCustomLightingCustom,o)
				surf(surfIN,o);
				#if defined(CAN_SKIP_VPOS)
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D(_DitherMaskLOD,float3(vpos.xy * 0.25,o.Alpha * 0.9375)).a;
				clip(alphaRef - 0.01);
				SHADOW_CASTER_FRAGMENT(IN)
			}
			ENDCG
		}
	}
	Fallback "Standard"
	CustomEditor "CarPaintInspector"
}
