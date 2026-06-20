import argparse
import sys
from pathlib import Path

import cv2
# MediaPipe only probes TensorFlow for documentation helpers. A partially
# installed TensorFlow must not prevent hand landmark extraction.
sys.modules.setdefault("tensorflow", None)
import mediapipe as mp
import numpy as np

from feature_utils import normalize_landmarks, resample_sequence


class HandDetector:
    def __init__(self, model_path):
        self.legacy = hasattr(mp, "solutions")
        if self.legacy:
            self.detector = mp.solutions.hands.Hands(
                static_image_mode=False,
                max_num_hands=1,
                min_detection_confidence=0.55,
                min_tracking_confidence=0.55,
            )
        else:
            options = mp.tasks.vision.HandLandmarkerOptions(
                base_options=mp.tasks.BaseOptions(model_asset_path=str(model_path)),
                running_mode=mp.tasks.vision.RunningMode.IMAGE,
                num_hands=1,
                min_hand_detection_confidence=0.55,
                min_hand_presence_confidence=0.55,
            )
            self.detector = mp.tasks.vision.HandLandmarker.create_from_options(options)

    def detect(self, rgb_frame):
        if self.legacy:
            result = self.detector.process(rgb_frame)
            if not result.multi_hand_landmarks:
                return None, None
            handedness = None
            if result.multi_handedness:
                handedness = result.multi_handedness[0].classification[0].label
            return result.multi_hand_landmarks[0].landmark, handedness

        image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb_frame)
        result = self.detector.detect(image)
        if not result.hand_landmarks:
            return None, None
        handedness = None
        if result.handedness and result.handedness[0]:
            handedness = result.handedness[0][0].category_name
        return result.hand_landmarks[0], handedness

    def close(self):
        self.detector.close()


def extract_video(video_path, detector):
    capture = cv2.VideoCapture(str(video_path))
    sequence = []
    while capture.isOpened():
        ok, frame = capture.read()
        if not ok:
            break
        landmarks_result, handedness = detector.detect(
            cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        )
        if landmarks_result is None:
            continue
        landmarks = [
            value
            for point in landmarks_result
            for value in (point.x, point.y, point.z)
        ]
        sequence.append(normalize_landmarks(landmarks, handedness))
    capture.release()
    if len(sequence) < 8:
        return None
    return resample_sequence(sequence)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("videos", type=Path, help="Folder containing one or more MP4 files per label")
    parser.add_argument("--output", type=Path, default=Path("sequence_dataset.npz"))
    parser.add_argument(
        "--hand-model",
        type=Path,
        default=Path(__file__).with_name("hand_landmarker.task"),
    )
    args = parser.parse_args()

    sequences = []
    labels = []
    if not hasattr(mp, "solutions") and not args.hand_model.exists():
        raise SystemExit(f"Hand landmark model was not found: {args.hand_model}")
    detector = HandDetector(args.hand_model)
    try:
        for video in sorted(args.videos.glob("*.mp4")):
            # Files may be named "label__01.mp4" to provide repetitions.
            label = video.stem.split("__", 1)[0].strip()
            sequence = extract_video(video, detector)
            if sequence is None:
                print(f"Skipped {video.name}: not enough detected hand frames")
                continue
            sequences.append(sequence)
            labels.append(label)
            print(f"Added {video.name} -> {label}")
    finally:
        detector.close()

    if not sequences:
        raise SystemExit("No usable videos were found")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    np.savez_compressed(
        args.output,
        sequences=np.asarray(sequences, dtype=np.float32),
        labels=np.asarray(labels),
    )
    print(f"Saved {len(sequences)} real sequences to {args.output}")


if __name__ == "__main__":
    main()
