# -*- coding: utf-8 -*-
"""
Medliva Deliverables Generator
Generates two 20-page PDF documents:
1. Medliva_UseCases_and_Features_AR.pdf (Arabic)
2. Medliva_UseCases_and_Features_EN.pdf (English)
"""

import os
import subprocess
import sys
import pypdf

WORKSPACE = r"c:\Users\Youseef\Desktop\New folder (6)"
CHROME_PATH = r"C:\Program Files\Google\Chrome\Application\chrome.exe"
if not os.path.exists(CHROME_PATH):
    CHROME_PATH = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

print(f"Browser path: {CHROME_PATH}")
