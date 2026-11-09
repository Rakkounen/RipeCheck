import os
import shutil
from pathlib import Path

BASE_DIR = Path("/Users/kyrios/Documents/MOBILE II/project_mobile")
DATASET_DIR = BASE_DIR / "assets" / "fruits" / "Dataset Kematangan" / "Dataset of Harumanis mango images for multi-modal"
OUTPUT_DIR = BASE_DIR / "training_data"

TRAIN_SRC = DATASET_DIR / "harumanis_phases_V2 augmented_700"
VAL_SRC = DATASET_DIR / "harumanis_phases_validation_88"
TEST_SRC = DATASET_DIR / "harumanis_phases_test_87"

# Standard 4 classes mapped to official labels
CLASS_MAP = {
    "rotten": "Mangga Harumanis Busuk",
    "ripe": "Mangga Harumanis Matang",
    "unripe": "Mangga Harumanis Mentah",
    "semi_ripe": "Mangga Harumanis Setengah Matang"
}

def clean_and_prepare():
    print(f"--> Menyiapkan dataset terstruktur di {OUTPUT_DIR}...")
    if OUTPUT_DIR.exists():
        shutil.rmtree(OUTPUT_DIR)
    
    for split in ["train", "val", "test"]:
        for label in CLASS_MAP.values():
            (OUTPUT_DIR / split / label).mkdir(parents=True, exist_ok=True)

    # Copy Train (700 images)
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

    # Copy Val (88 images)
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

    # Copy Test (87 images)
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

    print("\nDataset distribution summary:")
    for split in ["train", "val", "test"]:
        print(f"\n--- {split.upper()} ---")
        total = 0
        for label in sorted(CLASS_MAP.values()):
            count = len(list((OUTPUT_DIR / split / label).glob("*.*")))
            print(f"  {label}: {count} images")
            total += count
        print(f"  Total {split}: {total}")

if __name__ == "__main__":
    clean_and_prepare()

