// Early built-in-pipeline comic material used by the prototype. The same shader
// handles supplied textures and simple city materials; art direction is WIP.
Shader "ComicSpidey/HeroLit"
{
    Properties { _MainTex ("Texture", 2D) = "white" {} _Color ("Tint", Color) = (1,1,1,1) }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 150
        CGPROGRAM
        #pragma surface surf Comic
        sampler2D _MainTex;
        fixed4 _Color;
        struct Input { float2 uv_MainTex; float4 screenPos; };

        // Quantized diffuse lighting produces ink-like bands while retaining
        // Unity's directional light attenuation/shadow contribution.
        inline fixed4 LightingComic(SurfaceOutput s, fixed3 lightDir, fixed atten)
        {
            half intensity = saturate(dot(s.Normal, lightDir));
            half band = intensity < 0.2 ? 0.22 : intensity < 0.5 ? 0.48 : intensity < 0.8 ? 0.72 : 1.0;
            fixed4 result;
            result.rgb = s.Albedo * _LightColor0.rgb * band * atten;
            result.a = s.Alpha;
            return result;
        }

        void surf(Input IN, inout SurfaceOutput o)
        {
            fixed4 color = tex2D(_MainTex, IN.uv_MainTex) * _Color;
            // Subtle screen-space dot pattern in darker colours; the effect is
            // deliberately modest so details on the supplied suit remain legible.
            float2 pixel = floor((IN.screenPos.xy / max(IN.screenPos.w, 0.0001)) * _ScreenParams.xy / 3.0);
            half dotPattern = (1.0 - step(1.0, fmod(pixel.x, 2.0))) * (1.0 - step(1.0, fmod(pixel.y, 2.0)));
            half luminance = dot(color.rgb, half3(0.299, 0.587, 0.114));
            half shadowAmount = 1.0 - smoothstep(0.12, 0.65, luminance);
            o.Albedo = color.rgb * (1.0 - 0.12 * dotPattern * shadowAmount);
            o.Alpha = color.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
