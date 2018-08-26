package uk.aidanlee.gpu;

class RenderTexture extends Texture implements IRenderTarget
{
    public function new(_targetID, _textureID, _width, _height, _viewportScale)
    {
        super(_textureID, _width, _height);

        targetID      = _targetID;
        viewportScale = _viewportScale;
    }

    public var targetID : Int;

    public var viewportScale : Float;
}
