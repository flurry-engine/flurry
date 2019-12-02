import os
import io
import sys
import time
import subprocess
import unittest

from PIL import Image

class SystemTests(unittest.TestCase):
    def test_system_programs(self):
        xvfb_proc  = subprocess.Popen([ "Xvfb", ":99", "-screen", "0", "768x512x24" ])
        test_cases = [
            "BatcherDepth",
            "BatchingGeometry",
            "ClearColour",
            "Colourised",
            "DepthTesting",
            "GeometryDepth",
            "RenderTarget",
            "ShaderUniforms",
            "StencilTesting",
            "Text",
            "Transformations",
            "TransformationTree",
            "ImageSamplers"
        ]

        for x in test_cases:
            with self.subTest(x=x):
                templateHandle=open("Template.hxp", "r")
                template=templateHandle.read().replace("{TEST_CASE}", x)
                templateHandle.close()

                buildFileHandle=open("Build.hxp", "w")
                buildFileHandle.write(template)
                buildFileHandle.close()

                subprocess.run([ "npx", "lix", "run", "build", "build" ])

                myEnv = os.environ.copy()
                myEnv["DISPLAY"]=":99"
                test_proc=subprocess.Popen([ "bin/linux-x64/SystemTests" ], env=myEnv)

                time.sleep(1)

                subprocess.run([ "import", "-window", "Flurry", "-channel", "RGB", "-depth", "8", f"screenshot.png" ], env=myEnv)

                test_proc.kill()
                test_proc.wait()

                difference = subprocess.run([ "compare", "-metric", "AE", "-fuzz", "5%", f"expected/{x}.png", f"screenshot.png", "NULL:" ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
                self.assertEqual(int(difference.stderr), 0)

        os.remove("Build.hxp")
        os.remove("screenshot.png")

        xvfb_proc.kill()
        xvfb_proc.wait()

if __name__ == '__main__':
    unittest.main()