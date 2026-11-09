import os
import sys
import json

# Ensure current script folder is in sys.path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    # pyrefly: ignore[missing-import]
    import matplotlib.pyplot as plt
except ImportError:
    import matplotlib.pyplot as plt # type: ignore

try:
    from train_model import train_architecture
    from evaluate_model import evaluate_model
except ImportError:
    from training.train_model import train_architecture # type: ignore
    from training.evaluate_model import evaluate_model # type: ignore

def run_comparison():
    print("==========================================================")
    print("  KOMPARASI MODEL: EfficientNetB0 vs MobileNetV3Small")
    print("==========================================================")
    
    # 1. Train EfficientNetB0
    eff_model, eff_hist = train_architecture("efficientnet", epochs_phase1=8, epochs_phase2=10)
    eff_eval = evaluate_model("assets/models/efficientnet_model.keras", "EfficientNetB0")
    
    # 2. Train MobileNetV3Small
    mob_model, mob_hist = train_architecture("mobilenet", epochs_phase1=8, epochs_phase2=10)
    mob_eval = evaluate_model("assets/models/mobilenet_model.keras", "MobileNetV3Small")
    
    # 3. Plot Training Histories
    plt.figure(figsize=(14, 5))
    
    plt.subplot(1, 2, 1)
    plt.plot(eff_hist['accuracy'], label='EffNet Train Acc', color='blue', linestyle='--')
    plt.plot(eff_hist['val_accuracy'], label='EffNet Val Acc', color='blue')
    plt.plot(mob_hist['accuracy'], label='MobileNet Train Acc', color='green', linestyle='--')
    plt.plot(mob_hist['val_accuracy'], label='MobileNet Val Acc', color='green')
    plt.title('Training & Validation Accuracy')
    plt.xlabel('Epoch')
    plt.ylabel('Accuracy')
    plt.legend()
    plt.grid(True)
    
    plt.subplot(1, 2, 2)
    plt.plot(eff_hist['loss'], label='EffNet Train Loss', color='blue', linestyle='--')
    plt.plot(eff_hist['val_loss'], label='EffNet Val Loss', color='blue')
    plt.plot(mob_hist['loss'], label='MobileNet Train Loss', color='green', linestyle='--')
    plt.plot(mob_hist['val_loss'], label='MobileNet Val Loss', color='green')
    plt.title('Training & Validation Loss')
    plt.xlabel('Epoch')
    plt.ylabel('Loss')
    plt.legend()
    plt.grid(True)
    
    plt.tight_layout()
    plt.savefig("reports/training_history.png", dpi=300)
    plt.close()
    
    # Compare summary
    summary = {
        "EfficientNetB0": {
            "test_accuracy": eff_eval["accuracy"],
            "macro_f1": eff_eval["macro_avg_f1"],
            "weighted_f1": eff_eval["weighted_avg_f1"]
        },
        "MobileNetV3Small": {
            "test_accuracy": mob_eval["accuracy"],
            "macro_f1": mob_eval["macro_avg_f1"],
            "weighted_f1": mob_eval["weighted_avg_f1"]
        }
    }
    
    print("\n================ HASIL AKHIR KOMPARASI ================")
    for model_name, metrics in summary.items():
        print(f"[{model_name}] Test Acc: {metrics['test_accuracy']*100:.2f}% | Macro F1: {metrics['macro_f1']:.4f}")
        
    best_model_name = "EfficientNetB0" if summary["EfficientNetB0"]["macro_f1"] >= summary["MobileNetV3Small"]["macro_f1"] else "MobileNetV3Small"
    print(f"\n--> Model Terbaik Berdasarkan Macro F1: {best_model_name}")
    summary["best_model"] = best_model_name
    
    with open("reports/comparison_report.json", "w") as f:
        json.dump(summary, f, indent=2)
        
    return best_model_name

if __name__ == "__main__":
    run_comparison()

