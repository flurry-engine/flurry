import os
import io
import sys
import time
import subprocess
import unittest
import d3dshot
import win32gui
from PIL import Image
from pixelmatch.contrib.PIL import pixelmatch

d = d3dshot.create(capture_output="numpy")

def enumHandler(hwnd, lParam):
    if win32gui.IsWindowVisible(hwnd):
        if 'System Tests' in win32gui.GetWindowText(hwnd):
            left, top, right, bot = win32gui.GetClientRect(hwnd)
            lt = win32gui.ClientToScreen(hwnd, (left, top))
            rb = win32gui.ClientToScreen(hwnd, (right, bot))

            d.screenshot_to_disk(directory=None, file_name=lParam, region=lt + rb)

class SystemTests(unittest.TestCase):
    def test_system_programs(self):
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
            "ImGuiDrawing",
            "Painting"
        ]

        for x in test_cases:
            with self.subTest(x, x=x):
                print(x)

                templateHandle=open("template.json", "r")
                template=templateHandle.read().replace("{TEST_CASE}", x)
                templateHandle.close()

                buildFileHandle=open("build.json", "w")
                buildFileHandle.write(template)
                buildFileHandle.close()

                subprocess.run([ "npx", "neko", "../../run.n", "build", "--release" ], shell=True)

                test_proc=subprocess.Popen([ "bin/windows/SystemTests.exe" ])

                time.sleep(3)

                win32gui.EnumWindows(enumHandler, f"screenshot_{x}.png")

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

if __name__ == '__main__':
    unittest.main()
