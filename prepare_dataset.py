import os
import shutil
from pathlib import Path

# Paths
BASE_DIR = Path(".")
DATASET_DIR = BASE_DIR / "assets" / "fruits" / "Dataset Kematangan" / "Dataset of Harumanis mango images for multi-modal"
OUTPUT_DIR = BASE_DIR / "training_data"

TRAIN_SRC = DATASET_DIR / "harumanis_phases_V2 augmented_700"
VAL_SRC = DATASET_DIR / "harumanis_phases_validation_88"
TEST_SRC = DATASET_DIR / "harumanis_phases_test_87"

# Mapping classes to descriptive label names:
# Format: [Varietas] - [Tingkat Kematangan]
CLASS_MAP = {
    "unripe": "Mangga Harumanis Mentah",
    "semi_ripe": "Mangga Harumanis Setengah Matang",
    "ripe": "Mangga Harumanis Matang",
    "rotten": "Mangga Harumanis Busuk"
}

def clean_and_prepare():
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    
    for split in ["train", "val", "test"]:
        for label in CLASS_MAP.values():
            (OUTPUT_DIR / split / label).mkdir(parents=True, exist_ok=True)

    # Process Train (augmented 700)
    for folder_name in os.listdir(TRAIN_SRC):
        folder_path = TRAIN_SRC / folder_name
        if not folder_path.is_dir():
            continue
        key = folder_name.replace("_aug", "")
        if key in CLASS_MAP:
            target_label = CLASS_MAP[key]
            for img_file in folder_path.glob("*.*"):
                if img_file.suffix.lower() in [".jpg", ".jpeg", ".png"]:
                    shutil.copy2(img_file, OUTPUT_DIR / "train" / target_label / img_file.name)

    # Process Val (88)
    for folder_name in os.listdir(VAL_SRC):
        folder_path = VAL_SRC / folder_name
        if not folder_path.is_dir():
            continue
        key = folder_name.replace("_V", "")
        if key in CLASS_MAP:
            target_label = CLASS_MAP[key]
            for img_file in folder_path.glob("*.*"):
                if img_file.suffix.lower() in [".jpg", ".jpeg", ".png"]:
                    shutil.copy2(img_file, OUTPUT_DIR / "val" / target_label / img_file.name)

    # Process Test (87)
    for folder_name in os.listdir(TEST_SRC):
        folder_path = TEST_SRC / folder_name
        if not folder_path.is_dir():
            continue
        key = folder_name.replace("_T", "")
        if key in CLASS_MAP:
            target_label = CLASS_MAP[key]
            for img_file in folder_path.glob("*.*"):
                if img_file.suffix.lower() in [".jpg", ".jpeg", ".png"]:
                    shutil.copy2(img_file, OUTPUT_DIR / "test" / target_label / img_file.name)

    print("Dataset distribution summary:")
    for split in ["train", "val", "test"]:
        total = 0
        print(f"\n--- {split.upper()} ---")
        for label in sorted(CLASS_MAP.values()):
            count = len(list((OUTPUT_DIR / split / label).glob("*.*")))
            total += count
            print(f"  {label}: {count} images")
        print(f"  Total {split}: {total}")

if __name__ == "__main__":
    clean_and_prepare()

