Add-Type -AssemblyName System.IO.Compression.FileSystem
function Unzip
{
    param([string]$zipfile, [string]$outpath)

    [System.IO.Compression.ZipFile]::ExtractToDirectory($zipfile, $outpath)
}

Invoke-WebRequest -Uri "http://hxbuilds.s3-website-us-east-1.amazonaws.com/builds/haxe/windows64/haxe_latest.zip" -OutFile "$env:BASE_DIR\haxe.zip"
Invoke-WebRequest -Uri "https://github.com/HaxeFoundation/neko/releases/download/v2-2-0/neko-2.2.0-win64.zip" -OutFile "$env:BASE_DIR\neko.zip"

Unzip "$env:BASE_DIR\haxe.zip" "$env:BASE_DIR\haxe"
Unzip "$env:BASE_DIR\neko.zip" "$env:BASE_DIR\neko"

$env:Path += ";$env:BASE_DIR\haxe"
$env:Path += ";$env:BASE_DIR\neko"

$haxe_zip = Get-ChildItem "$env:BASE_DIR\haxe" | Select-Object -First 1
$neko_zip = Get-ChildItem "$env:BASE_DIR\neko" | Select-Object -First 1

Copy-Item -Path "$env:BASE_DIR\haxe\$haxe_zip\*" -Destination "$env:BASE_DIR\haxe" -Recurse -Force
Copy-Item -Path "$env:BASE_DIR\neko\$neko_zip\*" -Destination "$env:BASE_DIR\neko" -Recurse -Force

mkdir $BASE_DIR/haxelib
haxelib setup $BASE_DIR/haxelib

haxelib dev flurry $SOURCE_DIR
haxelib git hxcpp https://github.com/HaxeFoundation/hxcpp
haxelib git hxp https://github.com/openfl/hxp.git
haxelib git hxtelemetry https://github.com/jcward/hxtelemetry.git
haxelib git linc_imgui https://github.com/Aidan63/linc_imgui.git

haxelib run flurry install

cd $BASE_DIR/haxelib/hxcpp/git/tools/run
haxe compile.hxml
cd $BASE_DIR/haxelib/hxcpp/git/tools/hxcpp
haxe compile.hxml
