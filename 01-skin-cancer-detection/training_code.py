"""
training_code.py

Skin Cancer Detection Using Deep Learning (ResNet50)

This script trains a binary classifier to distinguish benign vs malignant
skin lesions using transfer learning with ResNet50.

It is meant as a clean, portfolio-ready version of the training code
used in the project.
"""

import os
from pathlib import Path

import matplotlib.pyplot as plt
import tensorflow as tf
from tensorflow.keras import callbacks, layers
from tensorflow.keras.applications import ResNet50
from tensorflow.keras.optimizers import AdamW


# -------------------- Configuration -------------------- #

# Path to your image dataset. In the original project this pointed to a
# directory with subfolders per class, e.g.:
#   xs_train/
#       benign/
#           img1.jpg ...
#       malignant/
#           img2.jpg ...
DATA_DIR = "content/image_data/xs_train"

IMG_HEIGHT = 224
IMG_WIDTH = 224
BATCH_SIZE = 10
VALIDATION_SPLIT = 0.2
SEED = 42
EPOCHS = 100

# Where to save plots (relative to where you run the script)
OUTPUT_DIR = Path("outputs")
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)


# -------------------- Dataset Preparation -------------------- #

def prepare_datasets():
    """
    Create training and validation tf.data.Dataset objects
    from an image directory.

    The directory is expected to have the structure:
        DATA_DIR/
            class_0/
            class_1/
    """
    if not os.path.isdir(DATA_DIR):
        raise FileNotFoundError(
            f"DATA_DIR does not exist: {DATA_DIR}\n"
            "Update DATA_DIR at the top of training_code.py to "
            "point to your image root folder."
        )

    train_ds = tf.keras.preprocessing.image_dataset_from_directory(
        DATA_DIR,
        validation_split=VALIDATION_SPLIT,
        subset="training",
        seed=SEED,
        image_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
    )

    val_ds = tf.keras.preprocessing.image_dataset_from_directory(
        DATA_DIR,
        validation_split=VALIDATION_SPLIT,
        subset="validation",
        seed=SEED,
        image_size=(IMG_HEIGHT, IMG_WIDTH),
        batch_size=BATCH_SIZE,
    )

    # Cache & prefetch for performance
    AUTOTUNE = tf.data.AUTOTUNE
    train_ds = train_ds.cache().shuffle(1000).prefetch(buffer_size=AUTOTUNE)
    val_ds = val_ds.cache().prefetch(buffer_size=AUTOTUNE)

    return train_ds, val_ds


# -------------------- Model Definition -------------------- #

def build_model(num_classes: int = 2) -> tf.keras.Model:
    """
    Build a transfer-learning model using ResNet50 as a frozen
    feature extractor, followed by custom dense layers.
    """
    base_model = ResNet50(
        include_top=False,
        input_shape=(IMG_HEIGHT, IMG_WIDTH, 3),
        weights="imagenet",
        pooling="avg",
    )

    # Freeze pretrained layers
    for layer in base_model.layers:
        layer.trainable = False

    model = tf.keras.Sequential(
        [
            base_model,
            layers.Flatten(),
            layers.Dense(64, activation="relu"),
            layers.Dense(num_classes, activation="softmax"),
        ]
    )

    model.compile(
        optimizer=AdamW(learning_rate=1e-4),
        loss="sparse_categorical_crossentropy",
        metrics=["accuracy"],
    )

    return model


# -------------------- Training & Plotting -------------------- #

def plot_history(history: tf.keras.callbacks.History, output_dir: Path) -> None:
    """
    Save accuracy and loss curves to PNG files in output_dir.
    """
    acc = history.history.get("accuracy", [])
    val_acc = history.history.get("val_accuracy", [])
    loss = history.history.get("loss", [])
    val_loss = history.history.get("val_loss", [])

    # Accuracy plot
    plt.figure(figsize=(6, 4))
    plt.plot(acc, label="Train Accuracy")
    plt.plot(val_acc, label="Val Accuracy")
    plt.title("Model Accuracy")
    plt.xlabel("Epoch")
    plt.ylabel("Accuracy")
    plt.legend()
    plt.grid(True, linestyle="--", alpha=0.4)
    acc_path = output_dir / "accuracy.png"
    plt.savefig(acc_path, bbox_inches="tight")
    plt.close()

    # Loss plot
    plt.figure(figsize=(6, 4))
    plt.plot(loss, label="Train Loss")
    plt.plot(val_loss, label="Val Loss")
    plt.title("Model Loss")
    plt.xlabel("Epoch")
    plt.ylabel("Loss")
    plt.legend()
    plt.grid(True, linestyle="--", alpha=0.4)
    loss_path = output_dir / "loss.png"
    plt.savefig(loss_path, bbox_inches="tight")
    plt.close()

    print(f"Saved accuracy plot to: {acc_path}")
    print(f"Saved loss plot to: {loss_path}")


def train():
    """
    End-to-end training entrypoint.
    """
    print("Preparing datasets...")
    train_ds, val_ds = prepare_datasets()

    print("Building model...")
    model = build_model(num_classes=2)
    model.summary()

    # Early stopping to restore best weights
    early_stopping = callbacks.EarlyStopping(
        monitor="val_loss",
        patience=5,
        restore_best_weights=True,
    )

    print("Starting training...")
    history = model.fit(
        train_ds,
        validation_data=val_ds,
        epochs=EPOCHS,
        callbacks=[early_stopping],
    )

    print("Training complete.")
    print("Saving accuracy/loss plots...")
    plot_history(history, OUTPUT_DIR)

    # Optional: save model (comment out if you don’t want large files)
    # model.save("skin_cancer_resnet50.keras")
    # print("Saved trained model to skin_cancer_resnet50.keras")


if __name__ == "__main__":
    train()
