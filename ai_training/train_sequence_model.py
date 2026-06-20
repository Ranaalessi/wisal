import argparse
import pickle
from collections import Counter
from pathlib import Path

import numpy as np
from sklearn.ensemble import ExtraTreesClassifier
from sklearn.metrics import classification_report
from sklearn.model_selection import train_test_split

from feature_utils import augment_sequence, sequence_features


def expand_sequences(sequences, labels, augment, rng):
    features = []
    targets = []
    for sequence, label in zip(sequences, labels):
        features.append(sequence_features(sequence))
        targets.append(label)
        for _ in range(augment):
            features.append(sequence_features(augment_sequence(sequence, rng)))
            targets.append(label)
    return np.asarray(features, dtype=np.float32), np.asarray(targets)


def create_model():
    return ExtraTreesClassifier(
        n_estimators=500,
        min_samples_leaf=2,
        class_weight="balanced",
        random_state=2026,
        n_jobs=-1,
    )


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", type=Path)
    parser.add_argument(
        "--output", type=Path, default=Path("server/wisal_model.pkl")
    )
    parser.add_argument("--augment", type=int, default=30)
    args = parser.parse_args()

    data = np.load(args.dataset, allow_pickle=False)
    sequences = data["sequences"]
    labels = data["labels"].astype(str)
    counts = Counter(labels)
    weak = [label for label, count in counts.items() if count < 5]
    if weak:
        print("Warning: record at least 5 real videos for:", ", ".join(weak))

    if min(counts.values()) >= 5:
        train_sequences, test_sequences, train_labels, test_labels = train_test_split(
            sequences,
            labels,
            test_size=0.2,
            random_state=2026,
            stratify=labels,
        )
        evaluation_rng = np.random.default_rng(2026)
        x_train, y_train = expand_sequences(
            train_sequences, train_labels, args.augment, evaluation_rng
        )
        x_test, y_test = expand_sequences(
            test_sequences, test_labels, 0, evaluation_rng
        )
        evaluation_model = create_model()
        evaluation_model.fit(x_train, y_train)
        print(
            classification_report(
                y_test, evaluation_model.predict(x_test), zero_division=0
            )
        )

    rng = np.random.default_rng(2026)
    features, targets = expand_sequences(sequences, labels, args.augment, rng)
    model = create_model()
    model.fit(features, targets)

    bundle = {
        "version": 2,
        "model": model,
        "sequence_length": 24,
        "confidence_threshold": 0.68,
        "classes": model.classes_.tolist(),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    with args.output.open("wb") as output_file:
        pickle.dump(bundle, output_file)
    print(f"Saved sequence model to {args.output}")


if __name__ == "__main__":
    main()
