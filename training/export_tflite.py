import os
import json
import numpy as np
import tensorflow as tf
from tensorflow import keras
from PIL import Image

def export_to_tflite(keras_model_path, output_tflite_path="assets/models/ripecheck_model.tflite"):
    print(f"\n--- EKSPOR MODEL KE TENSORFLOW LITE ---")
    print(f"Loading Keras model from: {keras_model_path}")
    model = keras.models.load_model(keras_model_path)
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    os.makedirs(os.path.dirname(output_tflite_path), exist_ok=True)
    with open(output_tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite model tersimpan di: {output_tflite_path} ({len(tflite_model)/1024/1024:.2f} MB)")
    
    # Verifikasi konsistensi numerik Keras vs TFLite
    interpreter = tf.lite.Interpreter(model_path=output_tflite_path)
    interpreter.allocate_tensors()
    
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    print("\nTFLite Input Details:", input_details[0]['shape'], input_details[0]['dtype'])
    print("TFLite Output Details:", output_details[0]['shape'], output_details[0]['dtype'])
    
    # Test sample inference on 5 test images
    test_dir = "training_data/test"
    labels = sorted(os.listdir(test_dir))
    diffs = []
    
    for label in labels:
        folder = os.path.join(test_dir, label)
        if not os.path.isdir(folder):
            continue
        imgs = [f for f in os.listdir(folder) if f.lower().endswith(('.jpg', '.jpeg', '.png'))]
        if not imgs:
            continue
        sample_path = os.path.join(folder, imgs[0])
        
        # Load image
        img = Image.open(sample_path).convert('RGB').resize((224, 224), Image.Resampling.BILINEAR)
        img_arr = np.expand_dims(np.array(img, dtype=np.float32), axis=0) # [1, 224, 224, 3] float32 [0..255]
        
        # Keras predict
        keras_pred = model.predict(img_arr, verbose=0)[0]
        
        # TFLite predict
        interpreter.set_tensor(input_details[0]['index'], img_arr)
        interpreter.invoke()
        tflite_pred = interpreter.get_tensor(output_details[0]['index'])[0]
        
        max_diff = np.max(np.abs(keras_pred - tflite_pred))
        diffs.append(max_diff)
        print(f"Sample [{label}] - Max Diff Keras vs TFLite: {max_diff:.6f}")
        
    print(f"\nRata-rata perbedaan absolut Keras vs TFLite: {np.mean(diffs):.6f}")
    
    # Simpan model_metadata.json
    metadata = {
        "model_name": "RipeCheck Harumanis Classifier",
        "input_shape": [1, 224, 224, 3],
        "input_dtype": "float32",
        "input_range": "[0, 255]",
        "color_format": "RGB",
        "labels": labels,
        "max_discrepancy_keras_vs_tflite": float(np.max(diffs)),
        "tflite_size_mb": round(len(tflite_model)/(1024*1024), 2)
    }
    with open("assets/models/model_metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)
    print("Metadata tersimpan di assets/models/model_metadata.json")

if __name__ == "__main__":
    import sys
    model_path = sys.argv[1] if len(sys.argv) > 1 else "assets/models/efficientnet_model.keras"
    export_to_tflite(model_path)

