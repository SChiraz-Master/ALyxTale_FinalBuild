﻿Shader "Capstone2019/ToonV3.31"
{
	Properties
	{
		[Toggle] _UseOutline("Outline Properties", Int) = 0

		_OutlineColor("Outline Color", Color) = (0,0,0,1)
		_OutlineWidth("Outline width", Range(0, 1)) = .1

		//==
		[Toggle] _UseToon("Toon Properties", Int) = 0

		_Ramp("Toon Ramp", 2D) = "white" {}
		_MainTex("Main Texture", 2D) = "white" {}

		[HDR]
		_AmbientColor("Ambient Color", Color) = (0.4,0.4,0.4,1)

		[HDR]
		_SpecularColor("Specular Color", Color) = (0.9,0.9,0.9,1)
		_Glossiness("Glossiness", Float) = 32

		[HDR]
		_RimColor("Rim Color", Color) = (1,1,1,1)
		_RimAmount("Rim Amount", Range(0, 1)) = 0.716

		_RimThreshold("Rim Threshold", Range(0, 1)) = 0.1

		//==
		[Toggle] _UseNormalMap("Normal Map Properties", Int) = 0

		_NormalMap("Normal Map Texture", 2D) = "bump" {}
		_NormalMapIntensity("Normal Map Intensity", Range(0,2)) = 1.5
		
		//==
		[Toggle] _UseEmission("Emission Properties", Int) = 0

		_EmissionMap("Emission Map", 2D) = "white" {}
		[HDR] _EmissionColor("Emission Color", Color) = (0,0,0,1)
		_EmissionIntensity("Emission Intensity", Range(0,1)) = 0

		//==
		[Toggle] _UseSnow("Snow Properties", Int) = 0

		_SnowText("Texture", 2D) = "white" {}
		_Factor("Amount of Snow", Range(0., 2.)) = 0
		_ObjYScale("YScale", float) = 0
	}

	CGINCLUDE
	#include "UnityCG.cginc"

	struct appdata
	{
		float4 vertex : POSITION;
	};

	struct v2f
	{
		float4 pos : POSITION;
	};

	uniform float _OutlineWidth;
	uniform float4 _OutlineColor;
	uniform sampler2D _MainTex;

	ENDCG

	SubShader
	{
		Tags{ "Queue" = "Transparent" "IgnoreProjector" = "True" }

		Pass //Outline
		{
			ZWrite Off
			Cull Back
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			v2f vert(appdata v)
			{
				appdata original = v;
				v.vertex.xyz += _OutlineWidth * normalize(v.vertex.xyz);

				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				return o;
			}

			half4 frag(v2f i) : COLOR
			{
				return _OutlineColor;
			}
			ENDCG
		}

		Tags{"Queue" = "Geometry"}

		CGPROGRAM
		#pragma surface surf Lambert

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_NormalMap;
		};

		sampler2D _NormalMap;

		void surf(Input IN, inout SurfaceOutput o)
		{
			fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;
		}
		ENDCG

		Pass // Toon
		{
			Tags
			{
				"LightMode" = "ForwardBase"
				"PassFlags" = "OnlyDirectional"
			}

			CGPROGRAM
			#pragma vertex vertT
			#pragma fragment fragT
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			float4 _MainTex_ST;

			sampler2D _Ramp;
			float4 _Ramp_ST;

			float _Glossiness;
			float4 _SpecularColor;

			float4 _RimColor;
			float _RimAmount;

			float _RimThreshold;

			sampler2D _NormalMap;
			float4 _NormalMap_ST;

			float _NormalMapIntensity;

			sampler2D _EmissionMap;
			float4 _EmissionMap_ST;

			float4 _EmissionColor;
			float _EmissionIntensity;

			struct appdataT
			{
				float4 vertex : POSITION;
				float4 uv : TEXCOORD0;
				float4 uvRamp : TEXCOORD1;
				float2 uvNormalMap: TEXCOORD2;
				float2 uvEmission: TEXCOORD3;
				float3 normal : NORMAL;
			};

			struct v2fT
			{
				float4 pos : SV_POSITION;
				float3 viewDir : TEXCOORD0;
				float2 uv : TEXCOORD1;
				float2 uvRamp : TEXCOORD2;
				float2 uvNormalMap : TEXCOORD3;
				float2 uvEmission: TEXCOORD4;
				float3 normal : NORMAL;
			};

			v2fT vertT(appdataT v)
			{
				v2fT o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.uvRamp = TRANSFORM_TEX(v.uvRamp, _Ramp);
				o.uvNormalMap = TRANSFORM_TEX(v.uvNormalMap, _NormalMap);
				o.uvEmission = TRANSFORM_TEX(v.uvEmission, _EmissionMap);

				o.normal = v.normal;
				o.viewDir = WorldSpaceViewDir(v.vertex);

				return o;
			}

			float4 _AmbientColor;

			float4 fragT(v2fT i) : SV_Target
			{
				float3 normal = normalize(i.normal); // World Normal Here
				float Ndot = dot(_WorldSpaceLightPos0, normal);

				float lightIntensity = smoothstep(0, 0.01, Ndot);
				float4 light = lightIntensity * _LightColor0;

				float3 viewDir = normalize(i.viewDir);
				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float NdotH = dot(normal, halfVector);

				float specularIntensity = pow(NdotH * lightIntensity, _Glossiness * _Glossiness);

				float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
				float4 specular = specularIntensitySmooth * _SpecularColor;

				float4 rimDot = 1 - dot(viewDir, normal);

				float rimIntensity = rimDot * pow(Ndot, _RimThreshold);
				rimIntensity = smoothstep(_RimAmount - 0.01, _RimAmount + 0.01, rimIntensity);

				float4 rim = rimIntensity * _RimColor;

				float4 NMap = tex2D(_NormalMap, i.uvNormalMap);
				float NM = (NMap.r + NMap.g + NMap.b) / 3;
				NM *= _NormalMapIntensity;

				return tex2D(_MainTex, i.uv) * tex2D(_Ramp, i.uvRamp) * (_AmbientColor + light + specular + rim) * NM + (tex2D(_EmissionMap, i.uvEmission) * _EmissionColor * _EmissionIntensity);
			}
			ENDCG
		}

		Tags{ "RenderType" = "Opaque" }
		Cull Off

		Pass // Snow
		{
			CGPROGRAM
			#pragma vertex vertS
			#pragma fragment fragS
			#pragma geometry geomS

			struct g2f // Appdata equivilant
			{
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed4 col : COLOR;
			};

			struct v2g // v2f equivilant
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : NORMAL;
			};

			sampler2D _SnowText;
			float4 _SnowText_ST;
			float _ObjYScale;
			

			v2g vertS(appdata_base v)
			{
				v2g o;
				o.vertex = v.vertex;
				o.uv = TRANSFORM_TEX(v.texcoord, _SnowText);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				return o;
			}

			float _Factor;

			[maxvertexcount(24)]
			void geomS(triangle v2g IN[3], inout TriangleStream<g2f> tristream)
			{
				if (_Factor > 0)
				{
					if (IN[0].vertex.y > _ObjYScale && IN[1].vertex.y > _ObjYScale && IN[2].vertex.y > _ObjYScale)
					{
						g2f o;
						for (int i = 0; i < 3; i++) // Side Trangles
						{
							o.pos = UnityObjectToClipPos(IN[i].vertex);
							o.uv = IN[i].uv;
							o.col = fixed4(0., 0., 0., 1.);
							tristream.Append(o);


							o.pos = UnityObjectToClipPos(IN[i].vertex + float4(0, 1, 0, 0) * _Factor);
							o.uv = IN[i].uv;
							o.col = fixed4(1., 1., 1., 1.);
							tristream.Append(o);

							int inext = (i + 1) % 3;

							o.pos = UnityObjectToClipPos(IN[inext].vertex);
							o.uv = IN[inext].uv;
							o.col = fixed4(0., 0., 0., 1.);
							tristream.Append(o);

							tristream.RestartStrip();

							o.pos = UnityObjectToClipPos(IN[i].vertex + float4(0, 1, 0, 0) * _Factor);
							o.uv = IN[i].uv;
							o.col = fixed4(1., 1., 1., 1.);
							tristream.Append(o);

							o.pos = UnityObjectToClipPos(IN[inext].vertex);
							o.uv = IN[inext].uv;
							o.col = fixed4(0., 0., 0., 1.);
							tristream.Append(o);

							o.pos = UnityObjectToClipPos(IN[inext].vertex + float4(0, 1, 0, 0) * _Factor);
							o.uv = IN[inext].uv;
							o.col = fixed4(1., 1., 1., 1.);
							tristream.Append(o);

							tristream.RestartStrip();
						}

						for (int i = 0; i < 3; i++) // Top Triangles
						{
							o.pos = UnityObjectToClipPos(IN[i].vertex + float4(0, 1, 0, 0) * _Factor);
							o.uv = IN[i].uv;
							o.col = fixed4(1., 1., 1., 1.);
							tristream.Append(o);
						}

						tristream.RestartStrip();
					}
				}
			}

			fixed4 fragS(g2f i) : SV_Target
			{
				fixed4 col = tex2D(_SnowText, i.uv) * i.col;
				return col;
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	//CustomEditor "ToonGUI"
}