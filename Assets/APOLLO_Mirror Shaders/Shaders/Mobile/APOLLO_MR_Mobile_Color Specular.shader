﻿
Shader "APOLLO_Mirror/Mobile/Color Specular" {
Properties {

     _ReflectionTex ("Reflection", 2D) = "white" { TexGen ObjectLinear }

	 _Blur ("Smoothness",Range(0.01,1)) = 0
	 _SpecularPower ("Specular Power", Range (0.0, 1)) = 0.5

	 [MaterialToggle] Metal ("Calculate Metalness", Float) = 0
	 _ReflectPower ("Metal Power", Range (0.0, 1)) = 0.1


	 	

    _Color ("Main Color", Color) = (0.5,0.5,0.5,1)

    	_SpeTex ("Specularity Map (A)", 2D) = "white" { }




}
SubShader {
	Tags { "RenderType"="Opaque"}
	LOD 200



CGPROGRAM
#pragma surface surf  BlinnPhong fullforwardshadows  
#pragma target 3.0
#pragma multi_compile _ METAL_ON 




sampler2D _ReflectionTex;
sampler2D _BumpMap;
sampler2D _SpeTex;


fixed4 _Color;
half _Shininess;
half _ReflectPower;
half _Blur;
half _NormSm;
half _AmbientC;
half _LightAdd;
half _PrPower;
half _AmbientLight;
half _Con;
half _SpecularPower;

struct Input {

    float4 screenPos;
    float2 uv_BumpMap;
    float2  uv_SpeTex;

};




void surf (Input IN, inout SurfaceOutput o) {

 
 	fixed4 s = tex2D(_SpeTex, IN.uv_SpeTex);



 o.Albedo = _Color;


    fixed3 normal = UnpackNormal(tex2D(_BumpMap, IN.uv_BumpMap)); 
    normal.z = normal.z; o.Normal = normalize(normal); 



  
 fixed2 screenUV = (IN.screenPos.xy) / (IN.screenPos.w);
  screenUV.xy += normal ;


 fixed4 hdrReflection = tex2Dlod (_ReflectionTex, float4( screenUV.xy, normal.z ,_Blur*10/s.a));






#if defined(METAL_ON)


	/////Calculate Metallic shading

	half3 mat = s.a/s.a-s.a*_ReflectPower;

	half3 met = hdrReflection.rgb*_Color*_ReflectPower;

	o.Albedo *= met*mat*_ReflectPower;
	o.Albedo += _Color*mat+met;



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

FallBack "Legacy Shaders/Diffuse"
}
