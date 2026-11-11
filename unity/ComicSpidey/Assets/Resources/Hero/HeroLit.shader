Shader "ComicSpidey/HeroLit"
{
    Properties { _MainTex ("Suit texture", 2D) = "white" {} _Color ("Tint", Color) = (1,1,1,1) }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 150
        CGPROGRAM
        #pragma surface surf Lambert
        sampler2D _MainTex;
        fixed4 _Color;
        struct Input { float2 uv_MainTex; };
        void surf(Input IN, inout SurfaceOutput o)
        {
            fixed4 color = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = color.rgb;
            o.Alpha = color.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
