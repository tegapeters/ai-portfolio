# Skin Cancer Detection Using Deep Learning (ResNet50)

Binary classifier to distinguish benign vs. malignant skin lesions using transfer learning. Built to evaluate whether smartphone-quality dermatoscopic images can support early melanoma detection.

## Results

| Metric | Value |
|--------|-------|
| Accuracy | **86.8%** |
| Malignant Precision | 71.6% |
| Malignant Recall | 36.8% |
| Benign Recall | Strong and stable |

Low malignant recall is consistent with class imbalance in the ISIC datasets — a known challenge in medical imaging.

## Architecture

- **Base model:** ResNet50 pretrained on ImageNet (all layers frozen)
- **Head:** Flatten → Dense(64, ReLU) → Dense(2, Softmax)
- **Optimizer:** AdamW, lr=1e-4
- **Loss:** Sparse categorical cross-entropy
- **Early stopping:** patience=5, restores best weights

## Dataset

- ISIC 2018 Challenge Dataset
- ISIC 2024 Archive
- Preprocessed to 224×224, normalized, batched
- Augmented: horizontal flip, rotation, zoom
- 80/20 train-validation split

## Stack

Python · TensorFlow/Keras · ResNet50 · AdamW · Matplotlib · Google Colab

## My Contributions

- Dataset organization and preprocessing pipeline
- Transfer learning model design and architecture decisions
- Hyperparameter tuning and training loop configuration
- Accuracy/loss curve visualization
- Model evaluation and interpretation writeup

## Files

- [`training_code.py`](training_code.py) — clean, documented training script
- [`report.pdf`](report.pdf) — full project report with evaluation analysis

## Future Work

- Fine-tune upper ResNet50 layers to improve malignant recall
- Add more malignant samples to address class imbalance
- Benchmark against EfficientNet, MobileNet, Vision Transformer
- Incorporate metadata (age, lesion area) for multimodal learning
- Export to TensorFlow Lite for mobile deployment
