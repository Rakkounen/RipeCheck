================================================================================
README — Harumanis Mango Maturity Image Dataset
================================================================================
Dataset Title : Dataset of Harumanis mango images for multi-modal maturity
                classification using ventral texture and size features
Version       : 4
DOI           : 10.17632/x6bcr3fkj5.4
Repository    : Mendeley Data
Contact       : nur atiqa basaruddin, Universiti Kuala Lumpur MIIT
================================================================================


--------------------------------------------------------------------------------
1. OVERVIEW
--------------------------------------------------------------------------------
This dataset contains images of Harumanis mango (Mangifera indica L.) collected
from five orchards in Perlis, Malaysia, across three consecutive harvesting
seasons (April to June 2023, 2024, and 2025). It was developed to support
automated maturity classification using image processing and machine learning
methods, specifically the TriFeat framework combining Histogram of Oriented
Gradients (HOG), Local Binary Patterns (LBP), and Gabor filter features.

The dataset consists of:
  - 272 original raw images (collected in the field)
  - 603 augmented images (generated from training images only)
  - 875 images total


--------------------------------------------------------------------------------
2. MATURITY CLASSES
--------------------------------------------------------------------------------
Each image is labelled into one of four maturity stages, assigned by expert
fruit growers following the FAMA (Federal Agricultural Marketing Authority)
weekly counting standard:

  Unripe     : Early developmental stage (~Week 1-2). Ventral surface displays
               noticeable wrinkle patterns; fruit size is relatively small.

  Semi-Ripe  : Intermediate growth stage (~Week 3-5). Wrinkle patterns reduce
               as the surface becomes smoother; fruit size increases.

  Ripe       : Near-harvest stage (~Week 6-8). Ventral surface is smooth with
               visible speckles; fruit has reached expected commercial size.

  Rotten     : Post-harvest deterioration. Surface shows discolouration, soft
               spots, and visible signs of decay.


--------------------------------------------------------------------------------
3. DATA COLLECTION
--------------------------------------------------------------------------------
Camera        : Nikon D5600 DSLR (18-55 mm f/3.5-5.6 lens)
Distance      : 10 cm from the mango's ventral surface
Background    : Black background to minimise reflection and shadow effects
Lighting      : Natural daylight, 9:00 a.m. to 2:00 p.m.
Resolution    : 2256 x 4000 pixels (original capture)
               Preprocessed to 2560 x 1443 pixels for model training
Region        : Ventral surface of the fruit (stem visible)
Orchards      : 5 orchards in Perlis, Malaysia
                  - Teluk Jambu
                  - Kampung Behor Gonchar
                  - D'Kebun Harumanis Paksu Maksu (Kampung Behor Gandil)
                  - Kampung Wang Ulu
                  - Kebun Nisah (Jalan Ujung Bukit, Kampung Tok Senai)
Seasons       : April to June 2023, 2024, 2025


--------------------------------------------------------------------------------
4. DATASET SPLIT AND AUGMENTATION — ORDER OF OPERATIONS
--------------------------------------------------------------------------------
IMPORTANT: Augmentation was performed AFTER splitting, and applied EXCLUSIVELY
to the training subset. Validation and test subsets contain only original,
non-augmented images. This design ensures no data leakage between subsets.

Step 1 — Split first (per class, based on available raw images):
  Training   :  97 original images
  Validation :  88 original images
  Test       :  87 original images
  Total      : 272 original images

Step 2 — Augment training subset only (rotation, flipping, brightness):
  Training expanded from 97 to 700 images (+603 augmented)
  Validation and test subsets left untouched (original images only)

Final dataset composition per class:

  Class       Train(raw)  Augmented  Train(final)  Validation  Test   Total
  ----------  ----------  ---------  ------------  ----------  ----   -----
  Unripe          20         144         164            20       19     203
  Semi-Ripe       22         150         172            20       19     211
  Ripe            39         201         240            44       46     330
  Rotten          16         108         124             4        3     131
  ----------  ----------  ---------  ------------  ----------  ----   -----
  TOTAL           97         603         700            88       87     875


--------------------------------------------------------------------------------
5. AUGMENTATION TECHNIQUES
--------------------------------------------------------------------------------
The following techniques were applied exclusively to the 97 training images:

  a) Rotation    : Images rotated at multiple angles to simulate variability
                   in fruit orientation and improve rotational robustness.

  b) Flipping    : Horizontal and vertical flipping applied to increase
                   diversity of ventral surface perspectives and reduce
                   positional bias.

  c) Brightness  : Brightness levels adjusted to simulate varying natural
                   lighting conditions across capture sessions.

No augmentation was applied to validation or test images.


--------------------------------------------------------------------------------
6. IMAGE PREPROCESSING PIPELINE
--------------------------------------------------------------------------------
All 875 images underwent the following five-step preprocessing pipeline
before use in model training and evaluation:

  1. Resizing           : Standardised to 2560 x 1443 pixels
  2. Greyscale          : Converted from RGB to greyscale
  3. Contrast           : CLAHE (Contrast Limited Adaptive Histogram
                          Equalisation) applied to enhance texture detail
  4. Noise reduction    : Gaussian filtering applied to reduce image noise
  5. Segmentation       : Four techniques applied to isolate the ventral
                          region — Otsu thresholding, morphological
                          processing, bounding box detection, and watershed
                          segmentation


--------------------------------------------------------------------------------
7. FILE STRUCTURE
--------------------------------------------------------------------------------
harumanis_phases_raw_272/
  Contains the 272 original raw images organised into 4 class subfolders:
    /ripe/               129 images
    /rotten/              23 images
    /semi_ripe/           61 images
    /unripe/              59 images
    labels original 272 images.csv

harumanis_phases_V2 augmented_700/
  Contains the 700 augmented training images organised into 4 class subfolders,
  each accompanied by an Excel image list file:
    /ripe_aug/           240 images (39 raw + 201 augmented)
    /rotten_aug/         124 images (16 raw + 108 augmented)
    /semi_ripe_aug/      172 images (22 raw + 150 augmented)
    /unripe_aug/         164 images (20 raw + 144 augmented)
    Ripe_Augmented_Image_List.xlsx
    Rotten_Augmented_Image_List.xlsx
    Semi_Ripe_Augmented_Image_List.xlsx
    Unripe_Augmented_Image_List.xlsx

harumanis_phases_validation_88/
  Contains the 88 original (non-augmented) validation images organised into
  4 class subfolders, each accompanied by an Excel image list file:
    /ripe_V/              44 images
    /rotten_V/             4 images
    /semi_ripe_V/         20 images
    /unripe_V/            20 images
    Ripe_Validation_Image_List.xlsx
    Rotten_Validation_Image_List.xlsx
    Semi_Ripe_Validation_Image_List.xlsx
    Unripe_Validation_Image_List.xlsx

harumanis_phases_test_87/
  Contains the 87 original (non-augmented) test images organised into
  4 class subfolders, each accompanied by an Excel image list file:
    /ripe_T/              46 images
    /rotten_T/             3 images
    /semi_ripe_T/         19 images
    /unripe_T/            19 images
    Ripe_Test_Image_List.xlsx
    Rotten_Test_Image_List.xlsx
    Semi_Ripe_Test_Image_List.xlsx
    Unripe_Test_Image_List.xlsx

README.txt
  This file.


--------------------------------------------------------------------------------
8. INTENDED USE
--------------------------------------------------------------------------------
This dataset is intended for researchers working on:
  - Agricultural image classification
  - Fruit maturity grading and quality assessment
  - Feature extraction benchmarking (texture, shape, size)
  - Machine learning model evaluation on small, real-world datasets

It was used to benchmark the TriFeat framework (HOG + LBP + Gabor) across
four classifiers (SVM, ANN, KNN, CNN) and four segmentation strategies.
The SVM + TriFeat combination achieved the best test accuracy of 98.85%.


--------------------------------------------------------------------------------
9. CITATION
--------------------------------------------------------------------------------
If you use this dataset, please cite:

  Basaruddin, N. A. (2026). Dataset of Harumanis mango images for
  multi-modal maturity classification using ventral texture and size
  features. Mendeley Data, V4.
  https://doi.org/10.17632/x6bcr3fkj5.4

Related article (Data in Brief — under review):
  Basaruddin, N. A. et al. A multi-season ventral image dataset of
  Harumanis mango for maturity classification using the TriFeat
  feature extraction framework. Data in Brief (2026).


--------------------------------------------------------------------------------
10. ETHICS
--------------------------------------------------------------------------------
This work does not involve human subjects, animal experiments, or data
collected from social media platforms. Image data were collected from
agricultural produce at orchards in Perlis, Malaysia, with the informed
consent and active participation of the orchard owners and fruit growers.


--------------------------------------------------------------------------------
11. FUNDING
--------------------------------------------------------------------------------
This research was supported by MARA (Majlis Amanah Rakyat), Malaysia.


================================================================================
END OF README
================================================================================
