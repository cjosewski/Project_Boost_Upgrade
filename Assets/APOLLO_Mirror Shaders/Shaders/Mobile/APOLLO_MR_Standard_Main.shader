
Shader "APOLLO_Mirror/Mobile/Main" {
Properties {

        _ReflectionTex ("Reflection", 2D) = "white" { TexGen ObjectLinear }

	 _Blur ("Smoothness",Range(0.01,1)) = 0
	 _SpecularPower ("Specular Power", Range (0.0, 1)) = 0.5

	 [MaterialToggle] Metal ("Calculate Metalness", Float) = 0
	 _ReflectPower ("Metal Power", Range (0.0, 1)) = 0.1

	 	 	
	_MainTex ("Main Texture (Albedo)", 2D) = "white" { }

	_SpeTex ("Specularity Map (A)", 2D) = "white" { }
	_MetTex ("Metalic Map (A)", 2D) = "white" { }


	_NormP ("Normalmap Power",Range(0.01,3)) = 1
	_BumpMap ("Normalmap", 2D) = "bump" { }







}
SubShader {
	Tags { "RenderType"="Opaque"}
	LOD 200



CGPROGRAM
#pragma surface surf Lambert  fullforwardshadows 
#pragma target 3.0
#pragma multi_compile _ METAL_ON 


sampler2D _SpeTex;
sampler2D _MainTex;
sampler2D _BumpMap;


sampler2D _ReflectionTex;


sampler2D _MetTex;
half _Shininess;
half _ReflectPower;
half _Blur;
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
	float2 uv_MetTex;
    float4 screenPos;
	float3 viewDir;

};




void surf (Input IN, inout SurfaceOutput o) {

 


	fixed4 tex = tex2D(_MainTex, IN.uv_MainTex);
	fixed4 s = tex2D(_SpeTex, IN.uv_SpeTex);
	fixed4 m = tex2D(_MetTex, IN.uv_MetTex);




 o.Albedo = tex.rgb*tex.a;



     

    fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); 
    normal.z = normal.z/_NormP; o.Normal = normalize(normal); 



  
 fixed2 screenUV = (IN.screenPos.xy) / (IN.screenPos.w);
  screenUV.xy += normal *_NormP;






           fixed4 hdrReflection = tex2Dlod (_ReflectionTex, float4( screenUV.xy, normal.z ,_Blur*10/s.a));






#if defined(METAL_ON)


	/////Calculate Metallic shading

	half3 mat = m.a/m.a-m.a*_ReflectPower;

	half3 met = hdrReflection.rgb*tex.rgb*m.a*_ReflectPower;

	o.Albedo *= met*mat*_ReflectPower;
	o.Albedo += tex.rgb*mat+met;



	// LB Lighting
    o.Albedo += _LightAdd;

	/////Calculate Specular shading
	o.Albedo += hdrReflection.rgb*hdrReflection.a*s.a*_SpecularPower;



	o.Emission -= o.Albedo* _Con*0.1;


	#else 

	// LB Lighting
    o.Albedo += _LightAdd;

	/////Calculate only Specular shading
	o.Albedo += hdrReflection.rgb*hdrReflection.a*s.a*_SpecularPower;



	o.Emission -= o.Albedo* _Con*0.1;

    #endif








o.Alpha = 1;

	 


}

 

ENDCG
}

FallBack "Legacy Shaders/Reflective/Bumped Specular"
}
