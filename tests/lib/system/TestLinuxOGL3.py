import os
import io
import sys
import time
import subprocess
import unittest
from PIL import Image
from pixelmatch.contrib.PIL import pixelmatch

class SystemTests(unittest.TestCase):
    def test_system_programs(self):
        xvfb_proc  = subprocess.Popen([ "Xvfb", ":99", "-screen", "0", "768x512x24", "-nolisten", "tcp", "-nolisten", "unix" ])
        test_cases = [
            "ClearColour",
            "Frames",
            "Shapes",
            "StencilTesting",
            "ImGuiDrawing",
            "Text"
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

                subprocess.run([ "npx", "neko", "../../run.n", "build", "--release", "--verbose", "--gpu", "ogl3" ], env=myEnv)

                test_proc=subprocess.Popen([ "bin/linux/SystemTests" ], env=myEnv)

                time.sleep(3)

                subprocess.run([ "import", "-window", "System Tests", f"screenshot_{x}.png" ], env=myEnv)

                test_proc.terminate()
                test_proc.wait()

                img_a = Image.open(f"expected/{x}.png")
                img_b = Image.open(f"screenshot_{x}.png")
                img_c = Image.new("RGBA", img_a.size)
                idiff = (pixelmatch(img_a, img_b, img_c) / (img_a.width * img_a.height)) * 100

                if idiff <= 5:
                    os.remove(f"screenshot_{x}.png")
                else:
                    os.rename(f"screenshot_{x}.png", f"screenshot_{x}_failed.png")
                    img_c.save(f"diff_{x}.png")
                    self.fail(f"expected image difference for {x} to be less than or equal to 5% but was {idiff}%")

        xvfb_proc.terminate()
        xvfb_proc.wait()

if __name__ == '__main__':
    unittest.main()
