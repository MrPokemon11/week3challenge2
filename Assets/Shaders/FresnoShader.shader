Shader "Custom/FresnoShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1,1,1,1)
        
        //dropdown for picking UV set
        [KeywordEnum(UV0,UV1)] _UVSET ("UV Set", Float) = 0
        
        //rim/fresnel demo
        _RimColor ("Rim Color", color) = (1,1,1,1)
        _RimPower ("Rim Power", Range(.5,8)) = 3
        _RimStrength ("Rim Strength", Range(0,1))=0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline"}
        LOD 200

        Pass
        {
            Name "Unlit" // samling only, there is no lighting
            Tags {"LightMode"="UniversalForward"}
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // create keywords the match the [KeywordEnum] above
            #pragma shader_feature_local _UVSET_UV0 _UVSET_UV1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            //Vertex I/O
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL; // added for rim/fresnel
                float2 uv0 : TEXCOORD0; // mesh uv channel 0
                float uv1 : TEXCOORD1; //mesh uv channel 1
            };
            
            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0; //uv chosen by dropdown

                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXTCOORD2;
            };

            // textures and samplers
            TEXTURE2D(_BaseMap);
            SAMPLER(sampler_BaseMap);

            //material (SRP Batcher)
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST;
                float4 _RimColor;
                float _RimPower;
                float _RimStrength;
            CBUFFER_END
            Varyings vert (Attributes IN)
            {
                Varyings OUT;
                

                //world data
                float3 posWS = TransformObjectToWorld(IN.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(IN.normalOS);

                OUT.positionWS = posWS;
                OUT.normalWS = nrmWS;
                OUT.positionHCS = TransformWorldToHClip(posWS);
                
                //choose uv set based on dropdown
                #if defined(_UVSET_UV1)
                    OUT.uv = TRANSFORM_TEX(IN.uv1,_BaseMap);
                #else //default is _UVSET_UV0
                    OUT.uv = TRANSFORM_TEX(IN.uv0,_BaseMap);
                #endif

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
                half3 color = baseTex.rgb * _BaseColor.rgb;

                // URP viewDir
                float3 viewDirWS = GetWorldSpaceViewDir(IN.positionWS);
                viewDirWS = SafeNormalize(viewDirWS);

                float3 n = SafeNormalize(IN.normalWS);
                float ndotv =saturate(dot(n, viewDirWS));
                float fres = pow(1-ndotv,_RimPower);
                color += (_RimColor.rgb * fres) * _RimStrength;

                return half4(color, 1.0);
            }

            ENDHLSL
        }
    }
    FallBack "Off"
}
