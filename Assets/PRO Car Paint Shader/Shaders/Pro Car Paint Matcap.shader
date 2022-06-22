Shader "Hidden / Pro Car Paint Matcap Shader"
{
	Properties
	{
		[HDR]_Color("Color",Color)= (0.5,0.5,0.5,1)
		[HDR]_SecondaryPaint("Secondary Paint",Color)= (0,0,0,1)
		_FresnelScale("Fresnel Scale",Range(0,1))= 0
		_FresnelPaintExponent("Fresnel Paint Exponent",Range(0,10))= 1
		_MainTex("MainTex",2D)= "black" {}
		[NoScaleOffset]_MatcapTexture("Matcap Texture",2D)= "gray" {}
		_ReflectionCubeMap("Reflection CubeMap",CUBE)= "black" {}
		_ReflectionIntensity("Reflection Intensity",Range(0,10))= 0.75
		_ReflectionStrength("Reflection Strength",Range(0,1))= 0.2
		_ReflectionBlur("Reflection Blur",Range(0,8))= 1
		_ReflectionExponent("Reflection Exponent",Range(0,10))= 0.5
		[Toggle]_ReflectionColorOverride("Reflection ColorOverride",Float)= 1
		[HDR]_ReflectionColor("Reflection Color",Color)= (1,1,1,1)
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
	}

	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
		LOD 200
		Cull Back

		Pass
		{
			CGPROGRAM
			#pragma vertex V
			#pragma fragment F
			#pragma multi_compile_fog

			#pragma target 3.0
			#pragma multi_compile	 REF_OFF 		REF
			#pragma multi_compile 	 DECALS_OFF 	DECALS
			#pragma multi_compile 	 REF_Over 		REF_Under

			#include "UnityCG.cginc"
			#include "UnityShaderVariables.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 normal : NORMAL;
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float4 texcoord : TEXCOORD0;
				float4 texcoord1 : TEXCOORD1;
				float4 texcoord2 : TEXCOORD2;
				float4 texcoord3 : TEXCOORD3;
				UNITY_FOG_COORDS(1)
			};

			uniform sampler2D _MatcapTexture;
			uniform float4 _SecondaryPaint;
			uniform float4 _Color;
			uniform float _FresnelScale;
			uniform float _FresnelPaintExponent;
			uniform sampler2D _MainTex;
			uniform float4 _MainTex_ST;
			uniform float _ReflectionColorOverride;
			uniform float4 _ReflectionColor;
			uniform samplerCUBE _ReflectionCubeMap;
			uniform fixed _ReflectionBlur;
			uniform float _ReflectionIntensity;
			uniform float _ReflectionExponent;
			uniform sampler2D _MetallicGlossMap;
			uniform float4 _MetallicGlossMap_ST;
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

			v2f V (appdata v)
			{
				v2f o;
				o.texcoord.xy = v.texcoord.xy;
				o.texcoord.zw = v.texcoord1.xy;
				float3 worldNormal = UnityObjectToWorldNormal(v.normal);
				o.texcoord1.xyz = worldNormal;
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				o.texcoord2.xyz = worldPos;
				float3 viewDir = UnityWorldSpaceViewDir(worldPos);
				float3 worldRefl = reflect(-viewDir,worldNormal);
				o.texcoord3.xyz = worldRefl;
				o.texcoord1.w = 0;
				o.texcoord2.w = 0;
				o.texcoord3.w = 0;
				o.vertex.xyz +=  float3(0,0,0);
				o.vertex = UnityObjectToClipPos(v.vertex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}

			fixed4 F (v2f i): SV_Target
			{
				float3 worldNormal = i.texcoord1.xyz;
				float3 worldPos = i.texcoord2.xyz;
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				float4 tex2D148 = tex2D(_MainTex,i.texcoord.xy*_MainTex_ST.xy + _MainTex_ST.zw);
				float4 FinalColor54 = lerp(_SecondaryPaint,_Color,(1.0 - (0.0 + _FresnelScale * pow(1.0 - dot(worldNormal,worldViewDir),_FresnelPaintExponent))));
				float4 BaseLayer1364 = lerp(FinalColor54,tex2D148,tex2D148.a);
				#ifdef REF
				float3 hsvTorgb480 = RGBToHSV(BaseLayer1364.rgb);
				float3 worldRefl = i.texcoord3.xyz;
				float fresnel1320 = (0.0 + _ReflectionIntensity * pow(1.0 - dot(worldNormal,worldViewDir),_ReflectionExponent));
				float Fer = (0.0 + (_ReflectionStrength + _ReflectionStrength)* pow(1.0 - dot(worldNormal,worldViewDir),_ReflectionExponent / 2.5));
				float ref_fres = saturate(_ReflectionStrength * Fer);
				float4 output_1318_0 = ((lerp(float4(HSVToRGB(float3(hsvTorgb480.x,hsvTorgb480.y,clamp((hsvTorgb480.z + 0.15),0.15,(float)1))),0.0),_ReflectionColor,_ReflectionColorOverride)* texCUBElod(_ReflectionCubeMap,float4(worldRefl,_ReflectionBlur))* fresnel1320));
				#ifdef REF_Under
				float4 Ref = lerp((BaseLayer1364 + output_1318_0),output_1318_0,ref_fres);
				#else
				float4 Ref = BaseLayer1364;
				#endif
				#else
				float4 Ref = BaseLayer1364;
				#endif
				#ifndef DECALS
				float4 Decals618 = Ref;
				#else
				float2 uv_1Decal = i.texcoord.xy * _1Decal_ST.xy + _1Decal_ST.zw;
				float4 tex2D238 = tex2D(_1Decal,uv_1Decal);
				float4 lerpResult417 = lerp(Ref,(_1DecalColor * tex2D238),tex2D238.a);
				float2 uv_2Decal = i.texcoord.xy * _2Decal_ST.xy + _2Decal_ST.zw;
				float4 tex2D1589 = tex2D(_2Decal,uv_2Decal);
				float4 lerpResult418 = lerp(lerpResult417,(_2DecalColor * tex2D1589),tex2D1589.a);
				float2 uv_3Decal = i.texcoord.xy * _3Decal_ST.xy + _3Decal_ST.zw;
				float4 tex2D1585 = tex2D(_3Decal,uv_3Decal);
				float4 lerpResult419 = lerp(lerpResult418,(_3DecalColor * tex2D1585),tex2D1585.a);
				float2 uv_4Decal = i.texcoord.xy * _4Decal_ST.xy + _4Decal_ST.zw;
				float4 tex2D1581 = tex2D(_4Decal,uv_4Decal);
				float4 lerpResult420 = lerp(lerpResult419,(_4DecalColor * tex2D1581),tex2D1581.a);
				float2 uv_5Decal = i.texcoord.xy * _5Decal_ST.xy + _5Decal_ST.zw;
				float4 tex2D1593 = tex2D(_5Decal,uv_5Decal);
				float4 lerpResult421 = lerp(lerpResult420,(_5DecalColor * tex2D1593),tex2D1593.a);
				float4 Decals618 = lerpResult421;
				#endif
				#ifdef REF
				#ifdef REF_Under
				float4 Final = Decals618;
				#else
				float4 Final = lerp((Decals618 + output_1318_0),output_1318_0,ref_fres);
				#endif
				#else
				float4 Final = Decals618;
				#endif
				UNITY_APPLY_FOG(i.fogCoord,Final);
				return (tex2D(_MatcapTexture,((mul(UNITY_MATRIX_V,float4(worldNormal,0.0))* 0.5)+ 0.5).xy)* Final * 2);
			}
			ENDCG
		}
	}
	Fallback "Standard"
	CustomEditor "CarPaintInspector"
}
