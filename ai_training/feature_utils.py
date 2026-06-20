import numpy as np


SEQUENCE_LENGTH = 24
LANDMARK_COUNT = 21
LANDMARK_COORDINATE_COUNT = LANDMARK_COUNT * 3
FEATURE_COUNT = LANDMARK_COORDINATE_COUNT + 3


def normalize_landmarks(landmarks, handedness=None):
    points = np.asarray(landmarks, dtype=np.float32).reshape(LANDMARK_COUNT, 3)
    wrist_position = points[0].copy()
    points = points - points[0]

    if handedness and handedness.lower() == "left":
        points[:, 0] *= -1
        wrist_position[0] = 1.0 - wrist_position[0]

    palm_size = np.linalg.norm(points[9])
    if palm_size < 1e-6:
        palm_size = np.max(np.linalg.norm(points, axis=1))
    if palm_size < 1e-6:
        palm_size = 1.0
    wrist_position[:2] -= 0.5
    return np.concatenate([(points / palm_size).reshape(-1), wrist_position])


def resample_sequence(sequence, length=SEQUENCE_LENGTH):
    values = np.asarray(sequence, dtype=np.float32)
    if values.ndim != 2 or values.shape[1] != FEATURE_COUNT:
        raise ValueError(f"Expected sequence shaped (frames, {FEATURE_COUNT})")
    if len(values) == 1:
        return np.repeat(values, length, axis=0)

    source = np.linspace(0.0, 1.0, len(values))
    target = np.linspace(0.0, 1.0, length)
    output = np.empty((length, FEATURE_COUNT), dtype=np.float32)
    for column in range(FEATURE_COUNT):
        output[:, column] = np.interp(target, source, values[:, column])
    return output


def sequence_features(sequence):
    sampled = resample_sequence(sequence)
    velocity = np.diff(sampled, axis=0, prepend=sampled[:1])
    return np.concatenate([sampled.reshape(-1), velocity.reshape(-1)])


def augment_sequence(sequence, rng):
    sampled = resample_sequence(sequence).copy()
    sampled += rng.normal(0.0, 0.012, sampled.shape).astype(np.float32)
    sampled *= rng.uniform(0.96, 1.04)
    return sampled
