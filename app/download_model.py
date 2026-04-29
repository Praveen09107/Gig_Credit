import urllib.request
import os

url = "https://raw.githubusercontent.com/sirius-ai/MobileFaceNet_TF/master/mobile_face_net.tflite"
output_path = r"C:\Users\PRAVEEN\Desktop\rotatech hackathon\Gig_Credit\app\assets\models\mobilefacenet.tflite"

print(f"Downloading {url} to {output_path}...")
try:
    urllib.request.urlretrieve(url, output_path)
    print("Download completed successfully!")
except Exception as e:
    print(f"Failed: {e}")
    # Alternative URL if the first fails
    url2 = "https://github.com/shubham0204/FaceRecognition_With_FaceNet_Android/raw/master/app/src/main/assets/mobile_face_net.tflite"
    print(f"Trying alternative URL: {url2}...")
    try:
        urllib.request.urlretrieve(url2, output_path)
        print("Download completed successfully via alternative!")
    except Exception as e2:
        print(f"Failed alternative: {e2}")
