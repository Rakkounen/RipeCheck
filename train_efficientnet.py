import os
from pathlib import Path

# Safe dynamic import for IDE language servers & virtual environments
try:
    import tensorflow as tf
    from tensorflow import keras
    from tensorflow.keras import layers
    # pyrefly: ignore[missing-import]
    from tensorflow.keras.applications import EfficientNetB0
except ImportError:
    import keras # type: ignore
    from keras import layers # type: ignore
    from keras.applications import EfficientNetB0 # type: ignore
    import tensorflow as tf # type: ignore

# Parameters
IMG_SIZE = (224, 224)
BATCH_SIZE = 16
NUM_CLASSES = 4
DATA_DIR = Path("training_data")
OUTPUT_DIR = Path("assets/models")

def main():
    print("TensorFlow Version:", tf.__version__)
    
    # 1. Load Datasets
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

    test_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR / "test",
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=False
    )

    class_names = train_ds.class_names
    print("\nClass Labels:", class_names)

    # Class Weights: Berikan bobot ekstra pada Mangga Busuk (kelas 0) agar tanda pembusukan tidak tertelan oleh kelas matang
    class_weights = {
        0: 2.50, # Busuk (prioritas tinggi deteksi nekrosis)
        1: 0.85, # Matang
        2: 1.10, # Mentah
        3: 1.05, # Setengah Matang
    }
    print("Class Weights:", class_weights)

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUTPUT_DIR / "labels.txt", "w") as f:
        for c in class_names:
            f.write(f"{c}\n")

    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.prefetch(buffer_size=AUTOTUNE)
    test_ds = test_ds.prefetch(buffer_size=AUTOTUNE)

    # Data Augmentation spesifik untuk citra lapangan (rotasi, zoom, kecerahan, kontras)
    data_augmentation = keras.Sequential([
        layers.RandomFlip("horizontal_and_vertical"),
        layers.RandomRotation(0.2),
        layers.RandomZoom(0.15),
        layers.RandomContrast(0.15),
    ], name="data_augmentation")

    inputs = layers.Input(shape=(IMG_SIZE[0], IMG_SIZE[1], 3), name="input_image")
    augmented = data_augmentation(inputs)

    # EfficientNetB0 Feature Extractor
    base_model = EfficientNetB0(
        include_top=False,
        weights="imagenet",
        input_tensor=augmented
    )

    # Fine-tuning: Buka 50 layer teratas agar mampu mempelajari tekstur bercak busuk
    base_model.trainable = True
    for layer in base_model.layers[:-50]:
        layer.trainable = False

    x = layers.GlobalAveragePooling2D(name="avg_pool")(base_model.output)
    x = layers.BatchNormalization()(x)
    x = layers.Dropout(0.4, name="top_dropout")(x)
    x = layers.Dense(128, activation="relu", name="dense_features")(x)
    x = layers.Dropout(0.2, name="feature_dropout")(x)
    outputs = layers.Dense(NUM_CLASSES, activation="softmax", name="predictions")(x)

    model = keras.Model(inputs=inputs, outputs=outputs, name="Harumanis_EfficientNetB0_Pro")

    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=2e-4),
        loss="categorical_crossentropy",
        metrics=["accuracy"]
    )

    callbacks = [
        keras.callbacks.EarlyStopping(monitor="val_loss", patience=5, restore_best_weights=True),
        keras.callbacks.ReduceLROnPlateau(monitor="val_loss", factor=0.5, patience=2, min_lr=1e-6)
    ]

    print("\nStarting Training & Fine-Tuning Professional Model...")
    model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=18,
        class_weight=class_weights,
        callbacks=callbacks
    )

    print("\nEvaluating on Test Set...")
    test_loss, test_acc = model.evaluate(test_ds)
    print(f"Test Accuracy: {test_acc * 100:.2f}% | Test Loss: {test_loss:.4f}")

    print("\nConverting model to TensorFlow Lite (.tflite)...")
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()

    tflite_path = OUTPUT_DIR / "ripecheck_model.tflite"
    with open(tflite_path, "wb") as f:
        f.write(tflite_model)
    print(f"TFLite model successfully saved to: {tflite_path} ({len(tflite_model) / 1024 / 1024:.2f} MB)")

if __name__ == "__main__":
    main()
