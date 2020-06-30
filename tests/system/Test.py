import os
import io
import sys
import time
import subprocess
import unittest

class SystemTests(unittest.TestCase):
    def test_system_programs(self):
        xvfb_proc  = subprocess.Popen([ "Xvfb", ":99", "-screen", "0", "768x512x24", "-nolisten", "tcp", "-nolisten", "unix" ])
        test_cases = [
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
            "Sprites",
            "Transformations",
            "TransformationTree",
            "ImGuiDrawing"
        ]

        myEnv = os.environ.copy()
        myEnv["DISPLAY"]=":99"

        for x in test_cases:
            with self.subTest(x, x=x):
                templateHandle=open("template.json", "r")
                template=templateHandle.read().replace("{TEST_CASE}", x)
                templateHandle.close()

                buildFileHandle=open("build.json", "w")
                buildFileHandle.write(template)
                buildFileHandle.close()

                subprocess.run([ "npx", "neko", "../../run.n", "build" ], env=myEnv)

                test_proc=subprocess.Popen([ "bin/linux/SystemTests" ], env=myEnv)

                time.sleep(2)

                subprocess.run([ "import", "-window", "System Tests", f"screenshot_{x}.png" ], env=myEnv)

                test_proc.terminate()
                test_proc.wait()

                imagemagick = subprocess.run([ "convert", "-metric", "ae", "-fuzz", "5%", f"expected/{x}.png", f"screenshot_{x}.png", "-trim", "-compare", "-format", "%[distortion]", "info:" ], stdout=subprocess.PIPE, text=True)
                diff        = int(imagemagick.stdout)

                if diff <= 10:
                    os.remove(f"screenshot_{x}.png")
                else:
                    os.rename(f"screenshot_{x}.png", f"screenshot_{x}_failed.png")
                    self.fail(f"expected image difference for {x} to be less or equal to 10 but was {diff}")

        xvfb_proc.terminate()
        xvfb_proc.wait()

if __name__ == '__main__':
    unittest.main()
