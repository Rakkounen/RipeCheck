import os
import json
try:
    import numpy as np
    import tensorflow as tf
    from tensorflow import keras
    # pyrefly: ignore[missing-import]
    from sklearn.metrics import classification_report, confusion_matrix
    # pyrefly: ignore[missing-import]
    import matplotlib.pyplot as plt
    # pyrefly: ignore[missing-import]
    import seaborn as sns
except ImportError:
    import numpy as np # type: ignore
    import tensorflow as tf # type: ignore
    import keras # type: ignore
    from sklearn.metrics import classification_report, confusion_matrix # type: ignore
    import matplotlib.pyplot as plt # type: ignore
    import seaborn as sns # type: ignore

IMG_SIZE = (224, 224)
BATCH_SIZE = 16
DATA_DIR = "training_data/test"
REPORTS_DIR = "reports"

def evaluate_model(model_path, model_name="model"):
    print(f"\n==============================================")
    print(f"  EVALUASI MODEL: {model_name} ({model_path})")
    print(f"==============================================")
    
    test_ds = tf.keras.utils.image_dataset_from_directory(
        DATA_DIR,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode="categorical",
        shuffle=False
    )
    
    class_names = test_ds.class_names
    print("Class labels:", class_names)
    
    model = keras.models.load_model(model_path)
    
    y_true_list = []
    y_pred_list = []
    y_pred_probs_list = []
    
    for images, labels in test_ds:
        preds = model.predict(images, verbose=0)
        y_true_list.extend(np.argmax(labels.numpy(), axis=1))
        y_pred_list.extend(np.argmax(preds, axis=1))
        y_pred_probs_list.extend(preds)
        
    y_true = np.array(y_true_list)
    y_pred = np.array(y_pred_list)
    
    # Classification Report
    cr = classification_report(y_true, y_pred, target_names=class_names, output_dict=True)
    cr_text = classification_report(y_true, y_pred, target_names=class_names)
    print("\n--- CLASSIFICATION REPORT ---")
    print(cr_text)
    
    # Confusion Matrix
    cm = confusion_matrix(y_true, y_pred)
    print("\n--- CONFUSION MATRIX ---")
    print(cm)
    
    # Plot Confusion Matrix
    os.makedirs(REPORTS_DIR, exist_ok=True)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=[c.replace('Mangga Harumanis ', '') for c in class_names],
                yticklabels=[c.replace('Mangga Harumanis ', '') for c in class_names])
    plt.title(f'Confusion Matrix - {model_name}')
    plt.ylabel('Ground Truth')
    plt.xlabel('Predicted')
    plt.tight_layout()
    cm_path = os.path.join(REPORTS_DIR, f"confusion_matrix_{model_name}.png")
    plt.savefig(cm_path, dpi=300)
    plt.close()
    
    # Save text report
    with open(os.path.join(REPORTS_DIR, f"classification_report_{model_name}.txt"), "w") as f:
        f.write(cr_text)
        
    return {
        "model_name": model_name,
        "accuracy": cr["accuracy"],
        "macro_avg_f1": cr["macro avg"]["f1-score"],
        "weighted_avg_f1": cr["weighted avg"]["f1-score"],
        "report": cr,
        "confusion_matrix": cm.tolist()
    }

if __name__ == "__main__":
    import sys
    path = sys.argv[1] if len(sys.argv) > 1 else "assets/models/efficientnet_model.keras"
    name = sys.argv[2] if len(sys.argv) > 2 else "efficientnet"
    evaluate_model(path, name)

