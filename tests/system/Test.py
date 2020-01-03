import os
import io
import sys
import time
import subprocess
import unittest

# We need the dummy test as for some reason the initial test will cause Xvfb / mesa / whatever to render nothing on azures VMs
# But after the first program has tried to render, all other will work fine...
class SystemTests(unittest.TestCase):
    def test_system_programs(self):
        xvfb_proc  = subprocess.Popen([ "Xvfb", ":99", "-screen", "0", "768x512x24", "-nolisten", "tcp", "-nolisten", "unix" ])
        test_cases = [
            "Dummy",
            "Colourised",
            "DepthTesting",
            "BatcherDepth",
            "GeometryDepth",
            "RenderTarget",
            "ShaderUniforms",
            "ClearColour",
            "BatchingGeometry",
            "StencilTesting",
            "Text",
            "Transformations",
            "TransformationTree",
            "ImageSamplers"
        ]

        myEnv = os.environ.copy()
        myEnv["DISPLAY"]=":99"
        myEnv["LIBGL_ALWAYS_SOFTWARE"]="1"
        myEnv["GALLIUM_DRIVER"]="softpipe"

        time.sleep(3)

        subprocess.run("glxinfo", env=myEnv)

        for x in test_cases:
            with self.subTest(x, x=x):
                templateHandle=open("template.json", "r")
                template=templateHandle.read().replace("{TEST_CASE}", x)
                templateHandle.close()

                buildFileHandle=open("build.json", "w")
                buildFileHandle.write(template)
                buildFileHandle.close()

                subprocess.run([ "npx", "lix", "run", "build", "build" ])

                test_proc=subprocess.Popen([ "bin/linux-x64/SystemTests" ], env=myEnv)

                time.sleep(1)

                subprocess.run([ "import", "-window", "System Tests", f"screenshot.png" ], env=myEnv)

                test_proc.terminate()
                test_proc.wait()

                imagemagick = subprocess.run([ "compare", "-metric", "AE", "-fuzz", "5%", f"expected/{x}.png", f"screenshot.png", "NULL:" ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                if (x == "Dummy"):
                    pass
                else:
                    self.assertLessEqual(int(imagemagick.stderr), 10)

        os.remove("build.json")
        os.remove("screenshot.png")

        xvfb_proc.terminate()
        xvfb_proc.wait()

if __name__ == '__main__':
    unittest.main()