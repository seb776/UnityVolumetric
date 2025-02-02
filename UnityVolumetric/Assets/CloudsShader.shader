Shader "Unlit/CloudsShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float3 _CloudBoxPosition;
            float3 _CloudBoxScale;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            // Taken here https://gist.github.com/patriciogonzalezvivo/670c22f3966e662d2f83
            float mod289(float x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 mod289(float4 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
            float4 perm(float4 x) { return mod289(((x * 34.0) + 1.0) * x); }

            float noise(float3 p) {
                float3 a = floor(p);
                float3 d = p - a;
                d = d * d * (3.0 - 2.0 * d);

                float4 b = a.xxyy + float4(0.0, 1.0, 0.0, 1.0);
                float4 k1 = perm(b.xyxy);
                float4 k2 = perm(k1.xyxy + b.zzww);

                float4 c = k2 + a.zzzz;
                float4 k3 = perm(c);
                float4 k4 = perm(c + 1.0);

                float4 o1 = frac(k3 * (1.0 / 41.0));
                float4 o2 = frac(k4 * (1.0 / 41.0));

                float4 o3 = o2 * d.z + o1 * (1.0 - d.z);
                float2 o4 = o3.yw * d.x + o3.xz * (1.0 - d.x);

                return o4.y * d.y + o4.x * (1.0 - d.y);
            }


            float sdCube(float3 p, float3 s)
            {
                float3 l = abs(p) - s;
                return max(l.x, max(l.y, l.z));
            }

            float map(float3 p)
            {
                return -sdCube(p, _CloudBoxScale*0.52) + noise(p*5.);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                //UNITY_APPLY_FOG(i.fogCoord, col);
                float3 viewDir = -normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                col.xyz = viewDir * 0.5 + 0.5;

                float3 p = i.worldPos.xyz;
                for (float i = 0.; i < 128.; ++i)
                {
                    float dist = map(p - _CloudBoxPosition);
                    if (dist < 0.01)
                    {
                        col.xyz = i/128.;
                        break;
                    }
                    p += viewDir * dist;
                }


                return col;
            }
            ENDCG
        }
    }
}
