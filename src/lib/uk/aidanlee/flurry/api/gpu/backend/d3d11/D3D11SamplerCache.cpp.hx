package uk.aidanlee.flurry.api.gpu.backend.d3d11;

import haxe.Exception;
import d3d11.constants.D3d11Error;
import d3d11.interfaces.D3d11Device.D3d11Device1;
import d3d11.interfaces.D3d11SamplerState;
import d3d11.structures.D3d11SamplerDescription;
import uk.aidanlee.flurry.api.gpu.backend.d3d11.D3D11Conversions;
import uk.aidanlee.flurry.api.gpu.textures.SamplerState;

using Safety;

class D3D11SamplerCache
{
    /**
     * D3D11 device samplers will be created using.
     */
    final device : D3d11Device1;

    /**
     * Reusable description object used for creating samplers.
     * Allows samplers to be created without any gc allocations.
     */
    final description : D3d11SamplerDescription;

    /**
     * All samplers currently created, keyed by their corresponding state.
     */
    final samplers : Map<SamplerState, D3d11SamplerState>;

    public function new(_device)
    {
        device      = _device;
        description = new D3d11SamplerDescription();
        samplers    = [];
    }

    /**
     * Return a D3D11 sampler state object for the provided flurry sampler.
     * If a D3D sampler with the required state has already been created that will be re-used.
     * @param _state State to get a sampler for
     * @throws Exception If creating the D3D11 sampler state fails.
     */
    public function get(_state)
    {
        return switch samplers.get(_state)
        {
            case null:
                @:nullSafety(Off) {
                    final sampler = new D3d11SamplerState();
                    description.filter         = getFilterType(_state.minification, _state.magnification);
                    description.addressU       = getEdgeClamping(_state.uClamping);
                    description.addressV       = getEdgeClamping(_state.vClamping);
                    description.addressW       = Clamp;
                    description.mipLodBias     = 0;
                    description.maxAnisotropy  = 1;
                    description.comparisonFunc = Never;
                    description.borderColor[0] = 1;
                    description.borderColor[1] = 1;
                    description.borderColor[2] = 1;
                    description.borderColor[3] = 1;
                    description.minLod         = -1;
                    description.minLod         = 1;

                    var result = Ok;
                    if (Ok != (result = device.createSamplerState(description, sampler)))
                    {
                        throw new Exception('Failed to create sampler state for $_state HRESULT : $result');
                    }

                    samplers[_state] = sampler;
                }
            case cached:
                cached.unsafe();
        }
    }
}