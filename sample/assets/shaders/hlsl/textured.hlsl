
// Default texture and sampler. This is the texture of the draw command.
Texture2D    defaultTexture : register(t0);
SamplerState defaultSampler : register(s0);

// cbuffer required in all HLSL shaders.
// Contains the two projection matrices for transforming input vertices
cbuffer requiredMatrices : register(b0)
{
	matrix projection;
	matrix view;
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

	output.position = mul(view      , float4(position, 1.0));
	output.position = mul(projection, output.position);
	output.color    = color;
	output.texcoord = texcoord;

	// Hack to convert between openGL's -1 to 1 clip space and DX's 0 to 1
	// http://anki3d.org/vulkan-coordinate-system/
	// Probably a better way to deal with this inside the matrix class, but it works for now
	output.position.z = (output.position.z + output.position.w) / 2.0f;

	return output;
}

float4 PShader(float4 position : SV_POSITION, float4 color : COLOR, float2 texcoord : TEXCOORD) : SV_TARGET
{
	return defaultTexture.Sample(defaultSampler, texcoord) * color;
}
