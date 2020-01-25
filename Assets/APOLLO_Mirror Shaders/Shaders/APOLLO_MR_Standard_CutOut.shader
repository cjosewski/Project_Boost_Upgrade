
Shader "APOLLO_Mirror/Cutout" {
Properties {

      _ReflectionTex ("Reflection", 2D) = "white" { TexGen ObjectLinear }

     _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
     

	 _Blur ("Roughness",Range(0.01,1)) = 10
	 _SpecularPower ("Specular Power", Range (0.0, 1)) = 0.0

	 [MaterialToggle] Metal ("Calculate Metalness", Float) = 0
	 _ReflectPower ("Metal Power", Range (0.0, 1)) = 0.1


	 _RimPower ("R Fresnel", Range(0,3.0)) = 1.0
	 	

    _Color ("Main Color", Color) = (0.5,0.5,0.5,1)
	_MainTex ("Main Texture (Albedo)", 2D) = "white" { }

	_SpeTex ("Specularity Map (A)", 2D) = "white" { }
	_MetTex ("Metalic Map (A)", 2D) = "white" { }


	[MaterialToggle] Ao ("Use Ambient Occlusion", Float) = 0
    _AOTex ("AO Map  (A)", 2D) = "white" { }

	_NormP ("Normalmap Power",Range(0.01,3)) = 1
	_BumpMap ("Normalmap", 2D) = "bump" { }






	[MaterialToggle] Prometheus ("Use Prometheus", Float) = 0
	_PrPower("Prometheus Value",Range(0,1)) = 1

}
SubShader {
     Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
    LOD 300



CGPROGRAM
#pragma surface surf Lambert alphatest:_Cutoff fullforwardshadows
#pragma target 3.0
#pragma multi_compile _ METAL_ON _ PROMETHEUS_ON  _ AO_ON _ CR_ON 


sampler2D _SpeTex;
sampler2D _MainTex;
sampler2D _BumpMap;
sampler2D _AOTex;


sampler2D _ReflectionTex;


sampler2D _MetTex;
fixed4 _Color;
half _Shininess;
half _ReflectPower;
half _Blur;
half _RimPower;
half _NormP;
half _NormSm;
half _AmbientC;
half _LightAdd;
half _PrPower;
half _AmbientLight;
half _Con;
half _SpecularPower;

struct Input {
	float2 uv_MainTex;
	float2 uv_BumpMap;
	float2 uv_SpeTex;
	float2 uv_AOTex;
	float2 uv_MetTex;
    float4 screenPos;
	float3 viewDir;

};




void surf (Input IN, inout SurfaceOutput o) {

 


	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex)*_Color;
	fixed4 s = tex2D(_SpeTex, IN.uv_SpeTex);
	fixed4 d= tex2D(_AOTex, IN.uv_AOTex);
	fixed4 m = tex2D(_MetTex, IN.uv_MetTex);




 o.Albedo = tex.rgb*tex.a;


       #if defined(PROMETHEUS_ON)

      o.Albedo *= o.Albedo*_PrPower*3;

      #endif


     

    fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); 
    normal.z = normal.z/_NormP; o.Normal = normalize(normal); 



  
 fixed2 screenUV = (IN.screenPos.xy) / (IN.screenPos.w);
  screenUV.xy += normal *_NormP;



     fixed4 hdrReflection = tex2Dlod (_ReflectionTex, float4( screenUV.xy, normal.z ,_Blur*10/s.a));


	 half rim = 1.5 - saturate(dot (normalize(IN.viewDir), o.Normal));





#if defined(METAL_ON)


	/////Calculate Metallic shading

	half3 mat = m.a/m.a-m.a*_ReflectPower;

	half3 met = hdrReflection.rgb*tex.rgb*m.a*_ReflectPower;

	o.Albedo *= met*mat*_ReflectPower;
	o.Albedo += tex.rgb*mat+met;



	// LB Lighting
    o.Albedo += _LightAdd;

	/////Calculate Specular shading
	o.Albedo += hdrReflection.rgb*hdrReflection.a*tex.a*s.a* pow (rim, _RimPower)*_SpecularPower;



	o.Emission -= o.Albedo* _Con*0.1;


	#else 

	// LB Lighting
    o.Albedo += _LightAdd;

	/////Calculate only Specular shading
	o.Albedo += hdrReflection.rgb*hdrReflection.a*tex.a*s.a* pow (rim, _RimPower)*_SpecularPower;



	o.Emission -= o.Albedo* _Con*0.1;

    #endif








  o.Alpha = tex.a;

	 
 #if defined(AO_ON)  

 o.Albedo *= d.a+o.Albedo-o.Emission/4;
 o.Albedo *= 0.5;
 #else
 o.Albedo *= 0.7;
 #endif

}

 

ENDCG
}

Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
}
