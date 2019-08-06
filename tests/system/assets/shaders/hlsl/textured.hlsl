Texture2D    defaultTexture : register(t0);
SamplerState defaultSampler : register(s0);

cbuffer defaultMatrices : register(b0)
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
	return defaultTexture.Sample(defaultSampler, texcoord) * color;
}