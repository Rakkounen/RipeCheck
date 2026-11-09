import os
import json
import argparse
from pathlib import Path
# Safe dynamic import for IDE language servers & virtual environments
try:
    import numpy as np
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers
    # pyrefly: ignore[missing-import]
    from tensorflow.keras.applications import EfficientNetB0, MobileNetV3Small
    # pyrefly: ignore[missing-import]
    import matplotlib.pyplot as plt
except ImportError:
    import numpy as np # type: ignore
    import tensorflow as tf # type: ignore
    import keras # type: ignore
    from keras import layers # type: ignore
    from keras.applications import EfficientNetB0, MobileNetV3Small # type: ignore
    import matplotlib.pyplot as plt # type: ignore

IMG_SIZE = (224, 224)
BATCH_SIZE = 16
NUM_CLASSES = 4
BASE_DIR = Path(".")
DATA_DIR = BASE_DIR / "training_data"
REPORTS_DIR = BASE_DIR / "reports"
MODELS_DIR = BASE_DIR / "assets" / "models"

def build_model(arch="efficientnet"):
    inputs = layers.Input(shape=(IMG_SIZE[0], IMG_SIZE[1], 3), name="input_image")
    
    # Mild & realistic data augmentation for mango photography
    data_augmentation = keras.Sequential([
        layers.RandomFlip("horizontal"),
        layers.RandomRotation(0.08),     # ~30 deg max
        layers.RandomZoom(0.08),         # mild zoom
        layers.RandomContrast(0.1),      # slight contrast variation
    ], name="data_augmentation")

    augmented = data_augmentation(inputs)

    if arch == "mobilenet":
        base_model = MobileNetV3Small(
            include_top=False,
            weights="imagenet",
            input_tensor=augmented
        )
        model_name = "RipeCheck_MobileNetV3Small"
        unfreeze_layers = 30
    else:
        base_model = EfficientNetB0(
            include_top=False,
            weights="imagenet",
            input_tensor=augmented
        )
        model_name = "RipeCheck_EfficientNetB0"
        unfreeze_layers = 40

    # Phase 1: Freeze base model
    base_model.trainable = False

    x = layers.GlobalAveragePooling2D(name="avg_pool")(base_model.output)
    x = layers.BatchNormalization(name="head_bn")(x)
    x = layers.Dropout(0.3, name="top_dropout")(x)
    x = layers.Dense(128, activation="relu", name="dense_features")(x)
    x = layers.Dropout(0.2, name="dropout_features")(x)
    outputs = layers.Dense(NUM_CLASSES, activation="softmax", name="predictions")(x)

    model = keras.Model(inputs=inputs, outputs=outputs, name=model_name)
    return model, base_model, unfreeze_layers

def train_architecture(arch="efficientnet", epochs_phase1=10, epochs_phase2=15):
    print(f"\n==================================================")
    print(f"   MEMULAI PELATIHAN MODEL: {arch.upper()}")
    print(f"==================================================")

    # 1. Load Data
    train_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR / "train",
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=True,
        seed=42
    )

    val_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR / "val",
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=False
    )

    class_names = train_ds.class_names
    print(f"Classes ({len(class_names)}): {class_names}")

    # Compute balanced class weights
    # train counts: Busuk: 124, Matang: 240, Mentah: 164, Setengah: 172 (Total: 700)
    # class_weight = N / (4 * count)
    class_weights = {
        0: 700 / (4 * 124),  # Busuk ~ 1.41
        1: 700 / (4 * 240),  # Matang ~ 0.73
        2: 700 / (4 * 164),  # Mentah ~ 1.06
        3: 700 / (4 * 172)   # Setengah Matang ~ 1.01
    }
    print("Computed Class Weights:", {k: round(v, 2) for k, v in class_weights.items()})

    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)

    model, base_model, unfreeze_count = build_model(arch)

    # TAHAP 1: Feature Extraction
    print(f"\n--- [TAHAP 1] Feature Extraction (Backbone Frozen) ---")
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-3),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )

    h1 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs_phase1,
        class_weight=class_weights
    )

    # TAHAP 2: Fine Tuning
    print(f"\n--- [TAHAP 2] Fine Tuning ({unfreeze_count} layers backbone dibuka) ---")
    base_model.trainable = True
    for layer in base_model.layers[:-unfreeze_count]:
        layer.trainable = False

    # Pastikan BatchNorm layers tetap freeze untuk stabilitas
    for layer in base_model.layers:
        if isinstance(layer, layers.BatchNormalization):
            layer.trainable = False

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=1e-4),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )

    callbacks = [
        keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, min_lr=1e-6)
    ]

    h2 = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=epochs_phase2,
        class_weight=class_weights,
        callbacks=callbacks
    )

    # Combine histories
    acc = h1.history['accuracy'] + h2.history['accuracy']
    val_acc = h1.history['val_accuracy'] + h2.history['val_accuracy']
    loss = h1.history['loss'] + h2.history['loss']
    val_loss = h1.history['val_loss'] + h2.history['val_loss']

    history = {
        'accuracy': [float(x) for x in acc],
        'val_accuracy': [float(x) for x in val_acc],
        'loss': [float(x) for x in loss],
        'val_loss': [float(x) for x in val_loss]
    }

    # Save model
    save_path = f"assets/models/{arch}_model.keras"
    model.save(save_path)
    print(f"Model tersimpan di: {save_path}")

    return model, history

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--arch", type=str, default="efficientnet", choices=["efficientnet", "mobilenet"])
    args = parser.parse_args()
    train_architecture(args.arch)

