#!/usr/bin/env python3
"""
RipeCheck EfficientNetB0 Retrain v2
====================================
Strategi:
1. Dataset kecil (~16-39 original per kelas + augmentasi manual) → gunakan
   ImageDataGenerator dari Keras preprocessing (bukan tf.data) supaya augmentasi 
   on-the-fly bisa dikontrol dan class_indices terjamin konsisten.
2. Karena training folder SUDAH berisi augmentasi manual (flip, rotasi, brightness),
   JANGAN tambahkan augmentasi rotation/flip lagi → hanya color jitter ringan.
3. Freeze SELURUH backbone EfficientNetB0, latih HEAD saja (5 epoch).
   Kemudian unfreeze 20 layer terakhir + fine-tune dengan lr sangat kecil (10 epoch).
4. Gunakan class weights karena distribusi tidak seimbang.
5. Preprocessing: EfficientNetB0 expects float32 [0..255] 
   (internal rescaling layer handles normalization).
"""

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

import numpy as np
import tensorflow as tf
from tensorflow.keras.applications import EfficientNetB0
from tensorflow.keras.preprocessing.image import ImageDataGenerator
from tensorflow.keras.layers import GlobalAveragePooling2D, Dense, Dropout, BatchNormalization
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau
from sklearn.metrics import classification_report, confusion_matrix
from collections import Counter

# ─── Paths ────────────────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TRAIN_DIR = os.path.join(BASE_DIR, 'training_data', 'train')
VAL_DIR = os.path.join(BASE_DIR, 'training_data', 'val')
TEST_DIR = os.path.join(BASE_DIR, 'training_data', 'test')
MODEL_OUT = os.path.join(BASE_DIR, 'assets', 'models', 'efficientnet_model.keras')

IMG_SIZE = (224, 224)
BATCH_SIZE = 16
NUM_CLASSES = 4

# ─── 1. Data Generators ──────────────────────────────────────────────────────
# Training: augmentasi RINGAN saja (data sudah di-augment manual di folder)
# Hanya tambahkan: brightness shift + channel shift kecil + zoom kecil
train_datagen = ImageDataGenerator(
    # JANGAN rescale! EfficientNetB0 punya internal rescaling layer.
    # Input harus float32 [0..255].
    rescale=None,
    brightness_range=[0.85, 1.15],
    channel_shift_range=20.0,
    zoom_range=0.1,
)

# Validasi & Test: tanpa augmentasi
val_datagen = ImageDataGenerator(rescale=None)
test_datagen = ImageDataGenerator(rescale=None)

print("Loading training data...")
train_gen = train_datagen.flow_from_directory(
    TRAIN_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=True,
    seed=42,
)

val_gen = val_datagen.flow_from_directory(
    VAL_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False,
    seed=42,
)

test_gen = test_datagen.flow_from_directory(
    TEST_DIR,
    target_size=IMG_SIZE,
    batch_size=BATCH_SIZE,
    class_mode='categorical',
    shuffle=False,
)

# ─── Print class indices ─────────────────────────────────────────────────────
print(f"\nClass indices: {train_gen.class_indices}")
print(f"Train samples: {train_gen.samples}")
print(f"Val samples:   {val_gen.samples}")
print(f"Test samples:  {test_gen.samples}")

# Verify label order matches labels.txt
labels_txt = os.path.join(BASE_DIR, 'assets', 'models', 'labels.txt')
if os.path.exists(labels_txt):
    with open(labels_txt) as f:
        saved_labels = [l.strip() for l in f if l.strip()]
    class_names = sorted(train_gen.class_indices.keys())
    print(f"\nlabels.txt:     {saved_labels}")
    print(f"Keras classes:  {class_names}")
    if saved_labels != class_names:
        print("⚠️  WARNING: labels.txt order != Keras class order! Updating labels.txt...")
        with open(labels_txt, 'w') as f:
            f.write('\n'.join(class_names) + '\n')
        print("✅ labels.txt updated.")
    else:
        print("✅ labels.txt matches Keras class order.")

# ─── 2. Compute Class Weights ────────────────────────────────────────────────
counter = Counter(train_gen.classes)
total = sum(counter.values())
class_weight = {}
for cls_id, count in counter.items():
    class_weight[cls_id] = total / (NUM_CLASSES * count)
print(f"\nClass weights: {class_weight}")

# ─── 3. Build Model ──────────────────────────────────────────────────────────
print("\nBuilding EfficientNetB0 model...")
base_model = EfficientNetB0(
    weights='imagenet',
    include_top=False,
    input_shape=(224, 224, 3),
)
# Freeze entire backbone
base_model.trainable = False

x = base_model.output
x = GlobalAveragePooling2D()(x)
x = BatchNormalization()(x)
x = Dropout(0.4)(x)
x = Dense(128, activation='relu')(x)
x = Dropout(0.3)(x)
predictions = Dense(NUM_CLASSES, activation='softmax')(x)

model = Model(inputs=base_model.input, outputs=predictions)

# ─── 4. Phase 1: Train head only ─────────────────────────────────────────────
print("\n" + "=" * 60)
print("PHASE 1: Training head only (backbone frozen)")
print("=" * 60)

model.compile(
    optimizer=Adam(learning_rate=1e-3),
    loss='categorical_crossentropy',
    metrics=['accuracy'],
)

phase1_callbacks = [
    EarlyStopping(
        monitor='val_accuracy',
        patience=4,
        restore_best_weights=True,
        verbose=1,
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=2,
        min_lr=1e-6,
        verbose=1,
    ),
]

history1 = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=12,
    class_weight=class_weight,
    callbacks=phase1_callbacks,
    verbose=1,
)

# ─── 5. Phase 2: Fine-tune last 20 layers ────────────────────────────────────
print("\n" + "=" * 60)
print("PHASE 2: Fine-tuning last 20 layers of backbone")
print("=" * 60)

base_model.trainable = True
# Freeze all layers EXCEPT last 20
for layer in base_model.layers[:-20]:
    layer.trainable = False
# Also freeze all BatchNormalization layers (critical for small datasets!)
for layer in base_model.layers:
    if isinstance(layer, tf.keras.layers.BatchNormalization):
        layer.trainable = False

trainable_count = sum(1 for l in model.layers if l.trainable)
print(f"Trainable layers: {trainable_count}")

model.compile(
    optimizer=Adam(learning_rate=5e-5),  # Very small LR for fine-tuning
    loss='categorical_crossentropy',
    metrics=['accuracy'],
)

phase2_callbacks = [
    EarlyStopping(
        monitor='val_accuracy',
        patience=5,
        restore_best_weights=True,
        verbose=1,
    ),
    ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=3,
        min_lr=1e-7,
        verbose=1,
    ),
]

history2 = model.fit(
    train_gen,
    validation_data=val_gen,
    epochs=15,
    class_weight=class_weight,
    callbacks=phase2_callbacks,
    verbose=1,
)

# ─── 6. Evaluate on Test Set ─────────────────────────────────────────────────
print("\n" + "=" * 60)
print("EVALUATION ON TEST SET")
print("=" * 60)

test_gen.reset()
y_pred_probs = model.predict(test_gen, verbose=0)
y_pred = np.argmax(y_pred_probs, axis=1)
y_true = test_gen.classes

# Class names in index order
idx_to_class = {v: k for k, v in test_gen.class_indices.items()}
class_names = [idx_to_class[i] for i in range(NUM_CLASSES)]

print(f"\nConfusion Matrix:")
cm = confusion_matrix(y_true, y_pred)
print(cm)

print(f"\nClassification Report:")
print(classification_report(y_true, y_pred, target_names=class_names, digits=3))

# Per-class accuracy
print("Per-class accuracy:")
for i, name in enumerate(class_names):
    mask = y_true == i
    if mask.sum() > 0:
        acc = (y_pred[mask] == i).sum() / mask.sum()
        print(f"  {name}: {acc:.1%} ({(y_pred[mask] == i).sum()}/{mask.sum()})")

# Show some predictions
print("\nSample predictions:")
test_gen.reset()
for cls in sorted(os.listdir(TEST_DIR)):
    cls_dir = os.path.join(TEST_DIR, cls)
    if not os.path.isdir(cls_dir):
        continue
    files = sorted([f for f in os.listdir(cls_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])[:2]
    for f in files:
        from PIL import Image
        im = Image.open(os.path.join(cls_dir, f)).convert('RGB').resize((224, 224))
        arr = np.expand_dims(np.array(im, dtype=np.float32), 0)
        preds = model.predict(arr, verbose=0)[0]
        pred_idx = np.argmax(preds)
        print(f"  Actual: {cls} -> Pred: {class_names[pred_idx]} ({preds[pred_idx]*100:.1f}%) | All: {[f'{p*100:.1f}%' for p in preds]}")

# ─── 7. Save Model ───────────────────────────────────────────────────────────
print(f"\nSaving model to {MODEL_OUT}...")
model.save(MODEL_OUT)
print("✅ Model saved!")

# ─── 8. Convert to TFLite ────────────────────────────────────────────────────
tflite_out = os.path.join(BASE_DIR, 'assets', 'models', 'ripecheck_model.tflite')
print(f"\nConverting to TFLite: {tflite_out}...")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
# Use float16 quantization for better accuracy than int8
converter.target_spec.supported_types = [tf.float16]

tflite_model = converter.convert()
with open(tflite_out, 'wb') as f:
    f.write(tflite_model)

print(f"✅ TFLite model saved! Size: {len(tflite_model) / 1024 / 1024:.1f} MB")

# ─── 9. Verify TFLite predictions match Keras ────────────────────────────────
print("\nVerifying TFLite predictions match Keras...")
interp = tf.lite.Interpreter(model_path=tflite_out)
interp.allocate_tensors()
inp_det = interp.get_input_details()[0]
out_det = interp.get_output_details()[0]

matches = 0
total_checked = 0
for cls in sorted(os.listdir(TEST_DIR)):
    cls_dir = os.path.join(TEST_DIR, cls)
    if not os.path.isdir(cls_dir):
        continue
    files = sorted([f for f in os.listdir(cls_dir) if f.lower().endswith(('.jpg', '.jpeg', '.png'))])[:3]
    for f in files:
        from PIL import Image
        im = Image.open(os.path.join(cls_dir, f)).convert('RGB').resize((224, 224))
        arr = np.expand_dims(np.array(im, dtype=np.float32), 0)
        
        # Keras prediction
        keras_pred = np.argmax(model.predict(arr, verbose=0)[0])
        
        # TFLite prediction
        interp.set_tensor(inp_det['index'], arr)
        interp.invoke()
        tflite_pred = np.argmax(interp.get_tensor(out_det['index'])[0])
        
        if keras_pred == tflite_pred:
            matches += 1
        total_checked += 1

print(f"Keras↔TFLite agreement: {matches}/{total_checked} ({matches/total_checked*100:.0f}%)")
print("\n🎉 Training pipeline complete!")
