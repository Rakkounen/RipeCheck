import os
import json
import numpy as np
import tensorflow as tf
from PIL import Image

def verify_preprocessing():
    test_img_path = "training_data/test/Mangga Harumanis Matang"
    img_files = [os.path.join(test_img_path, f) for f in os.listdir(test_img_path) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
    if not img_files:
        print("Tidak ada file test ditemukan.")
        return
    
    sample_img = img_files[0]
    print(f"Sample test image: {sample_img}")

    # 1. PIL Preprocessing (Python standard)
    img = Image.open(sample_img).convert('RGB')
    img_resized = img.resize((224, 224), Image.Resampling.BILINEAR)
    np_img = np.array(img_resized, dtype=np.float32) # [0, 255] float32

    # 2. tf.keras Preprocessing
    tf_img = tf.keras.utils.load_img(sample_img, target_size=(224, 224))
    tf_arr = tf.keras.utils.img_to_array(tf_img) # [0, 255] float32

    diff = np.max(np.abs(np_img - tf_arr))
    print(f"Beda tensor PIL vs tf.keras: {diff:.4f}")
    print(f"Shape: {np_img.shape}, Min: {np_img.min()}, Max: {np_img.max()}, Dtype: {np_img.dtype}")

    # Simpan sample tensor & preprocessed image
    os.makedirs("reports", exist_ok=True)
    img_resized.save("reports/preprocessed_sample.png")
    print("Preprocessed image tersimpan di reports/preprocessed_sample.png")

if __name__ == "__main__":
    verify_preprocessing()

