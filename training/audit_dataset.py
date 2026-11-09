import os
import hashlib
import json
from collections import defaultdict
from PIL import Image

BASE_DIR = "/Users/kyrios/Documents/MOBILE II/project_mobile"
RAW_DATA_DIR = os.path.join(BASE_DIR, "assets/fruits/Dataset Kematangan/Dataset of Harumanis mango images for multi-modal")
OUTPUT_REPORT = os.path.join(BASE_DIR, "reports/audit_report.json")

def get_image_hash(file_path):
    hasher = hashlib.md5()
    with open(file_path, "rb") as f:
        buf = f.read()
        hasher.update(buf)
    return hasher.hexdigest()

def check_image_validity(file_path):
    try:
        with Image.open(file_path) as img:
            img.verify()
        with Image.open(file_path) as img:
            format_name = img.format
            mode = img.mode
            size = img.size
        return True, None, format_name, mode, size
    except Exception as e:
        return False, str(e), None, None, None

def audit():
    print("=== MEMULAI AUDIT DATASET RIPECHECK ===")
    
    subdirs = {
        "raw_272": os.path.join(RAW_DATA_DIR, "harumanis_phases_raw_272"),
        "augmented_700": os.path.join(RAW_DATA_DIR, "harumanis_phases_V2 augmented_700"),
        "validation_88": os.path.join(RAW_DATA_DIR, "harumanis_phases_validation_88"),
        "test_87": os.path.join(RAW_DATA_DIR, "harumanis_phases_test_87")
    }

    report = {
        "splits_info": {},
        "corrupt_images": [],
        "duplicates_within_split": {},
        "cross_split_duplicates": [],
        "class_distribution": {},
        "image_modes": defaultdict(int),
        "image_formats": defaultdict(int),
        "sizes": defaultdict(int),
    }

    file_hashes = {}  # hash -> list of (split, rel_path)

    for split_name, split_path in subdirs.items():
        if not os.path.exists(split_path):
            print(f"Warning: Direktori {split_path} tidak ditemukan!")
            continue
        
        split_counts = defaultdict(int)
        seen_in_split = set()
        split_duplicates = []

        for root, dirs, files in os.walk(split_path):
            for file in files:
                if file.startswith(".") or file.lower().endswith(".txt"):
                    continue
                file_path = os.path.join(root, file)
                rel_path = os.path.relpath(file_path, RAW_DATA_DIR)
                class_name = os.path.basename(root)

                split_counts[class_name] += 1

                # Verify validity
                is_valid, err, fmt, mode, size = check_image_validity(file_path)
                if not is_valid:
                    report["corrupt_images"].append({"file": rel_path, "error": err})
                    continue
                
                report["image_modes"][mode] += 1
                report["image_formats"][fmt] += 1
                report["sizes"][f"{size[0]}x{size[1]}"] += 1

                # Check hash
                img_hash = get_image_hash(file_path)
                if img_hash in seen_in_split:
                    split_duplicates.append(rel_path)
                else:
                    seen_in_split.add(img_hash)

                if img_hash not in file_hashes:
                    file_hashes[img_hash] = []
                file_hashes[img_hash].append((split_name, rel_path))

        report["splits_info"][split_name] = dict(split_counts)
        report["duplicates_within_split"][split_name] = split_duplicates

    # Check cross split duplicates (Data leakage)
    for img_hash, occurrences in file_hashes.items():
        splits_present = set([occ[0] for occ in occurrences])
        if len(splits_present) > 1:
            report["cross_split_duplicates"].append({
                "hash": img_hash,
                "occurrences": occurrences
            })

    # Summary
    print("\n--- RINGKASAN DATASET ---")
    for split, counts in report["splits_info"].items():
        total = sum(counts.values())
        print(f"Split {split} (Total {total}):")
        for cls, count in counts.items():
            print(f"  - {cls}: {count}")

    print(f"\nGambar Rusak / Corrupt: {len(report['corrupt_images'])}")
    print(f"Cross-split Duplicates (Potential Leakage): {len(report['cross_split_duplicates'])}")
    for split, dups in report["duplicates_within_split"].items():
        if dups:
            print(f"Duplikat internal pada {split}: {len(dups)}")

    # Format dicts for json
    report["image_modes"] = dict(report["image_modes"])
    report["image_formats"] = dict(report["image_formats"])
    report["sizes"] = dict(report["sizes"])

    os.makedirs(os.path.dirname(OUTPUT_REPORT), exist_ok=True)
    with open(OUTPUT_REPORT, "w") as f:
        json.dump(report, f, indent=2)
    print(f"\nAudit selesai! Laporan lengkap tersimpan di: {OUTPUT_REPORT}")

if __name__ == "__main__":
    audit()

