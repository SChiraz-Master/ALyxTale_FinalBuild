Shader "Capstone2019/GrassNoKeep"
{
    Properties
    {
		[Toggle] _UseVege("Blade Properties", Int) = 0
		//==
		_TopColor("Top Color", Color) = (1,1,1,1)
		_BottomColor("Bottom Color", Color) = (1,1,1,1)
		_GradThresh("Gradiant Threshold", Range(0,1)) = 0.5 //_TranslucentGain

		_BendRotationRandom("Bend Rotation Random", Range(0, 4)) = 0

		_BladeForward("Blade Forward Amount", Range(0, 2)) = 0
		_BladeCurve("Blade Curvature Amount", Range(1, 4)) = 2

		_BladeHeight("Blade Height", Float) = 0.1
		_BladeHeightRandom("Random Height Variation", Range(0, 2)) = 0 // Random Variation

		_BladeWidth("Blade Width", Float) = 0
		_BladeWidthRandom("Random Width Variation", Range(0, 2)) = 0 // Random Variation

		_WindDistortionMap("Wind Distortion Map", 2D) = "white" {}
		_WindFrequency("Wind Direction", Vector) = (0.05, 0.05, 0, 0)
		_WindStrength("Wind Strength", Range(0.01, 1)) = 1

		_TessellationUniform("Density", Range(1, 64)) = 1
    }

	CGINCLUDE
	#include "UnityCG.cginc"
	#include "Autolight.cginc"
	#include "Lighting.cginc"
	#include "CustomTessellation.cginc"

	#define BLADE_SEGMENTS 3

	float _BendRotationRandom;

	float _BladeHeight;
	float _BladeHeightRandom;

	float _BladeWidth;
	float _BladeWidthRandom;

	float _BladeForward;
	float _BladeCurve;

	sampler2D _WindDistortionMap;
	float4 _WindDistortionMap_ST;

	float2 _WindFrequency;
	float _WindStrength;

	sampler2D _MainTex;
	float4 _MainTex_ST;

	float rand(float3 co)
	{
		return frac(sin(dot(co.xyz, float3(12.9898, 78.233, 53.539))) * 43758.5453);
	}

	float3x3 AngleAxis3x3(float angle, float3 axis)  // Create Rotation Matrix that rotates around the provided axis, sourced from: https://gist.github.com/keijiro/ee439d5e7388f3aafc5296005c8c3f33
	{
		float c, s;
		sincos(angle, s, c);

		float t = 1 - c;
		float x = axis.x;
		float y = axis.y;
		float z = axis.z;

		return float3x3(
			t * x * x + c, t * x * y - s * z, t * x * z + s * y,
			t * x * y + s * z, t * y * y + c, t * y * z - s * x,
			t * x * z - s * y, t * y * z + s * x, t * z * z + c
			);
	}

	struct v2g
	{
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		unityShadowCoord4 _ShadowCoord : TEXCOORD1;
		float3 normal : NORMAL;
	};

	v2g OutputData(float3 pos, float2 uv, float3 normal)
	{
		v2g o;
		o.pos = UnityObjectToClipPos(pos);
		o.uv = uv;
		o._ShadowCoord = ComputeScreenPos(o.pos);
		o.normal = UnityObjectToWorldNormal(normal);

		//#if UNITY_PASS_SHADOWCASTER // Take this off to enable grass blades to imit shadows on themselves
		//	o.pos = UnityApplyLinearShadowBias(o.pos);
		//#endif
		return o;
	}

	v2g GenVertData(float3 vertexPosition, float width, float height, float forward, float2 uv, float3x3 transformMatrix) //here
	{
		float3 tangentPoint = float3(width, forward, height);

		float3 tangentNormal = normalize(float3(0, -1, forward));
		float3 localNormal = mul(transformMatrix, tangentNormal);

		float3 localPosition = vertexPosition + mul(transformMatrix, tangentPoint);
		return OutputData(localPosition, uv, localNormal);
	}

	[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
	void geo(point vertexOutput IN[1], inout TriangleStream<v2g> triStream)
	{
		float3 pos = IN[0].vertex;
		float3 vNormal = IN[0].normal;
		float4 vTangent = IN[0].tangent;
		float3 vBinormal = cross(vNormal, vTangent) * vTangent.w;

		float3x3 tangentToLocal = float3x3(
			vTangent.x, vBinormal.x, vNormal.x,
			vTangent.y, vBinormal.y, vNormal.y,
			vTangent.z, vBinormal.z, vNormal.z
			);
		
		float3x3 facingRotationMatrix = AngleAxis3x3(rand(pos) * UNITY_TWO_PI, float3(0, 0, 1));
		float3x3 bendRotationMatrix = AngleAxis3x3(rand(pos.zzx) * _BendRotationRandom * UNITY_PI * 0.5, float3(-1, 0, 0));

		float2 uv = pos.xz * _WindDistortionMap_ST.xy + _WindDistortionMap_ST.zw + _WindFrequency * _Time.y; // Wind applied Here
		float2 windSample = (tex2Dlod(_WindDistortionMap, float4(uv, 0, 0)).xy * 2 - 1) * _WindStrength;  // Put safety net there blades are still rendered if no wind
		float3 wind = normalize(float3(windSample.x, windSample.y, 0));

		float3x3 windRotation = AngleAxis3x3(UNITY_PI * windSample, wind);

		float3x3 transformationMatrix = mul(mul(mul(tangentToLocal, windRotation), facingRotationMatrix), bendRotationMatrix);

		float3x3 transformationMatrixFacing = mul(tangentToLocal, facingRotationMatrix);

		float height = (rand(pos.zyx) * 2 - 1) * _BladeHeightRandom + _BladeHeight;
		float width = (rand(pos.xzy) * 2 - 1) * _BladeWidthRandom + _BladeWidth;

		float forward = rand(pos.yyz) * _BladeForward;

		for (int i = 0; i < BLADE_SEGMENTS; i++)
		{
			float t = i / (float)BLADE_SEGMENTS;
			float segmentHeight = height * t;
			float segmentWidth = width * (1 - t);
			float segmentForward = pow(t, _BladeCurve) * forward;
			float3x3 transformMatrix = i == 0 ? transformationMatrixFacing : transformationMatrix;

			triStream.Append(GenVertData(pos, segmentWidth, segmentHeight, segmentForward, float2(0, t), transformMatrix));
			triStream.Append(GenVertData(pos, -segmentWidth, segmentHeight, segmentForward, float2(1, t), transformMatrix));
		}

		triStream.Append(GenVertData(pos, 0, height, forward, float2(0.5, 1), transformationMatrix));
	}
	ENDCG

	SubShader
	{
		Pass
		{
			Tags
			{
				"RenderType" = "Opaque"
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment fragC
			#pragma target 4.6
			#pragma geometry geo
			#pragma hull hull
			#pragma domain domain
			#pragma multi_compile_fwdbase

			#include "Lighting.cginc"

			float4 _TopColor;
			float4 _BottomColor;
			float _GradThresh;

			float4 fragC(v2g i, fixed facing : VFACE) : SV_Target
			{
				float3 normal = facing > 0 ? i.normal : -i.normal;

				float shadow = SHADOW_ATTENUATION(i);
				float NdotL = saturate(saturate(dot(normal, _WorldSpaceLightPos0)) + _GradThresh) * shadow;

				float3 ambient = ShadeSH9(float4(normal, 1));
				float4 lightIntensity = NdotL * _LightColor0 + float4(ambient, 1);
				float4 col = lerp(_BottomColor, _TopColor * lightIntensity, i.uv.y);
				return col;
			}
			ENDCG
		}

		Pass
		{
			Tags
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM
			#pragma vertex vert
			#pragma geometry geo
			#pragma fragment frag
			#pragma hull hull
			#pragma domain domain
			#pragma target 4.6
			#pragma multi_compile_shadowcaster

			float4 frag(v2g i) : SV_Target
			{
				SHADOW_CASTER_FRAGMENT(i)
			}

			ENDCG
		}
	}
	FallBack "Capstone2019/ToonV4" // Create Basic Texture Fallback (with Cell shader)
	CustomEditor "VegeGUI"
}