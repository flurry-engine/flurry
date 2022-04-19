package igloo.tools;

import hx.files.Path;

class Tools
{
    public final msdfAtlasGen : Path;

    public final glslang : Path;

    public final spirvcross : Path;

	public function new(_msdfAtlasGen, _glslang, _spirvcross)
    {
		msdfAtlasGen = _msdfAtlasGen;
		glslang      = _glslang;
		spirvcross   = _spirvcross;
	}
}