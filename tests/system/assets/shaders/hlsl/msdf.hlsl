Texture2D    defaultTexture : register(t0);
SamplerState defaultSampler : register(s0);

cbuffer flurry_matrices : register(b0)
{
	matrix projection;
	matrix view;
	matrix model;
};

struct VOut
{
	float4 position : SV_POSITION;
	float4 color    : COLOR;
	float2 texcoord : TEXCOORD;
};

float median(float3 v)
{
	return max( min(v.x, v.y), min( max(v.x, v.y), v.z ) );
}

VOut VShader(float3 position : POSITION, float4 color : COLOR, float2 texcoord : TEXCOORD)
{
	VOut output;

	output.position = mul(model     , float4(position, 1.0));
	output.position = mul(view      , output.position);
	output.position = mul(projection, output.position);
	output.color    = color;
	output.texcoord = texcoord;

	return output;
}

float4 PShader(float4 position : SV_POSITION, float4 color : COLOR, float2 texcoord : TEXCOORD) : SV_TARGET
{
	float width;
    float height;
    defaultTexture.GetDimensions(width, height);

	float2 msdfUnit = 2.0 / float2(width, height);
	float3 sampled  = defaultTexture.Sample(defaultSampler, texcoord).rgb;
	float  sigDist  = median(sampled) - 0.5;
	sigDist *= dot(msdfUnit, 0.5 / fwidth(texcoord));

	return float4(color.r, color.g, color.b, clamp(sigDist + 0.5, 0.0, 1.0));
}