import os
import json
import argparse
import numpy as np
import tensorflow as tf
from PIL import Image

def predict_mango(image_path, model_path="assets/models/ripecheck_model.tflite", labels_path="assets/models/labels.txt"):
    if not os.path.exists(image_path):
        print(f"Error: Gambar {image_path} tidak ditemukan.")
        return
        
    with open(labels_path, "r") as f:
        labels = [l.strip() for l in f.readlines() if l.strip()]
        
    interpreter = tf.lite.Interpreter(model_path=model_path)
    interpreter.allocate_tensors()
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    # Preprocessing
    img = Image.open(image_path).convert("RGB").resize((224, 224), Image.Resampling.BILINEAR)
    img_arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0) # [1, 224, 224, 3] [0..255]
    
    interpreter.set_tensor(input_details[0]['index'], img_arr)
    interpreter.invoke()
    preds = interpreter.get_tensor(output_details[0]['index'])[0]
    
    best_idx = int(np.argmax(preds))
    confidence = float(preds[best_idx])
    predicted_label = labels[best_idx]
    
    # Keamanan Prediksi: Ambang batas keyakinan (confidence threshold)
    CONFIDENCE_THRESHOLD = 0.60
    is_confident = confidence >= CONFIDENCE_THRESHOLD
    
    result = {
        "varietas": "Harumanis",
        "tingkat_kematangan": predicted_label.replace("Mangga Harumanis ", ""),
        "confidence": round(confidence * 100, 2),
        "is_confident": is_confident,
        "probabilities": {lbl.replace("Mangga Harumanis ", ""): round(float(p) * 100, 2) for lbl, p in zip(labels, preds)}
    }
    
    print("\n--- HASIL PREDIKSI CITRA ---")
    print(f"File              : {image_path}")
    print(f"Varietas          : {result['varietas']}")
    print(f"Kematangan        : {result['tingkat_kematangan']}")
    print(f"Confidence        : {result['confidence']}%")
    print(f"Probabilitas      : {result['probabilities']}")
    
    if not is_confident:
        print("\n[PERINGATAN] Foto belum dapat dianalisis dengan yakin (Keyakinan < 60%).")
        print("Silakan ambil foto ulang dengan pencahayaan yang lebih baik atau posisikan mangga di tengah frame.")
    else:
        print("\n[STATUS] Prediksi valid dan layak ditampilkan.")
        
    return result

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("image_path", type=str, help="Path ke foto mangga")
    args = parser.parse_args()
    predict_mango(args.image_path)

