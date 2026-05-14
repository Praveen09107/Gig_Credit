import os
import re

BASE = r'C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit'

def search_codebase(pattern, ignore_files=None):
    if ignore_files is None: ignore_files = []
    found = []
    for root, dirs, files in os.walk(BASE):
        if 'node_modules' in root or '.git' in root or '__pycache__' in root or 'build' in root or '.dart_tool' in root:
            continue
        for file in files:
            if not file.endswith(('.dart', '.py', '.yaml', '.json')):
                continue
            if file in ignore_files:
                continue
            
            filepath = os.path.join(root, file)
            try:
                with open(filepath, 'r', encoding='utf-8') as f:
                    content = f.read()
                    matches = re.finditer(pattern, content, re.IGNORECASE)
                    for m in matches:
                        start = max(0, m.start() - 30)
                        end = min(len(content), m.end() + 30)
                        found.append((filepath, content[start:end].replace('\n', ' ')))
            except:
                pass
    return found

print('--- CHECKING FOR MOCKS AND SECURITY ISSUES ---')

print('\n[1] Checking for hardcoded OTP 0000...')
otp_matches = search_codebase(r'[\'\"`]\s*0000\s*[\'\"`]|000000')
for fp, ctx in otp_matches:
    print(f'  Found in {os.path.basename(fp)}: {ctx}')

print('\n[2] Checking for mock_api_service...')
mock_api = search_codebase(r'mock_api_service')
for fp, ctx in mock_api:
    print(f'  Found in {os.path.basename(fp)}: {ctx}')

print('\n[3] Checking for local IPs (172.x or localhost)...')
local_ips = search_codebase(r'172\.\d+\.\d+\.\d+|localhost|127\.0\.0\.1')
for fp, ctx in local_ips:
    if 'test' not in fp and 'dev' not in fp:
        print(f'  Found in {os.path.basename(fp)}: {ctx}')

print('\n[4] Checking for fake/fallback JSON responses...')
fallbacks = search_codebase(r'return \{.*?fake.*?\}', ignore_files=['demo_profile_service.dart'])
for fp, ctx in fallbacks:
    print(f'  Found in {os.path.basename(fp)}: {ctx}')

print('\n[5] Checking OCR API usage (Should be local PaddleOCR)...')
ocr_usage = search_codebase(r'http[s]?://.*/ocr')
for fp, ctx in ocr_usage:
    print(f'  Found in {os.path.basename(fp)}: {ctx}')
