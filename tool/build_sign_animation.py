import json
import math
import struct
import sys
from pathlib import Path


JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942
FLOAT = 5126
REST = [0.0] * 9

# Local Euler deltas solved against the exported avatar skeleton.
POSES = {
    "rest": REST,
    "salute": [0.6581, -0.5652, -1.2692, 1.2033, -1.0446, -1.0132, 0.0, 0.0, 0.0],
    "salam_chest": [0.3898, -0.1408, -0.3424, 1.0080, 0.6826, 0.8306, 0.0, 0.0, 0.0],
    "salam_up": [0.480106, -0.057952, -0.354019, 1.102678, 0.806451, 0.854515, 0.0, 0.0, 0.0],
    "salam_down": [0.339141, -0.210566, -0.312806, 0.874346, 0.550923, 0.800562, 0.0, 0.0, 0.0],
    "absher": [1.099995, -0.090716, -0.376201, 1.166535, 0.907197, 0.822432, 0.12, -0.10, -0.18],
    "love_chest": [0.715837, -0.143163, -0.310532, 1.096298, 0.805254, 0.876766, 0.08, -0.32, -0.12],
    "love_forward": [1.10645, -0.257257, -0.175967, 0.634135, 0.262005, 0.456048, -0.08, -0.18, 0.08],
    "pain": [0.143153, -0.419891, -0.664828, 1.240885, -0.716517, -0.551435, 0.16, -0.36, -0.24],
    "angry_chest": [0.803677, -0.122447, -0.261158, 1.102478, 0.813965, 0.877265, 0.05, -0.28, -0.10],
    "angry_face": [1.353933, -0.375285, -0.608198, 1.228086, 0.693028, 0.544157, 0.18, -0.20, -0.30],
    "annoyed_upper": [0.880288, -0.148112, -0.268185, 1.102291, 0.813798, 0.876729, 0.04, -0.30, -0.08],
    "annoyed_lower": [0.485156, -0.176643, -0.085352, 0.823133, 0.505762, 0.784295, 0.02, -0.26, -0.05],
    "bank_r": [0.479014, -0.628173, -1.129593, 1.212953, -0.856379, -0.672662, 0.05, -0.28, -0.42],
    "bank_l": [0.364457, 0.431572, 1.279051, 1.160682, 0.822003, 0.729244, 0.05, 0.28, 0.42],
}


ANIMATIONS = [
    {
        "name": "salam_alaykum_full",
        "times": [0.0, 0.25, 1.2, 1.65, 2.4, 2.7, 3.0, 3.3, 3.6, 3.95, 4.6],
        "right": ["rest", "rest", "salute", "salute", "salam_chest", "salam_up", "salam_down", "salam_up", "salam_down", "salam_chest", "rest"],
        "right_curl": [0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0],
    },
    {
        "name": "absher_hader",
        "times": [0.0, 0.25, 0.8, 1.25, 1.65, 2.1, 2.65],
        "right": ["rest", "rest", "absher", "absher", "absher", "rest", "rest"],
        "right_curl": [0.0, 0.0, 0.75, 0.95, 0.75, 0.0, 0.0],
    },
    {
        "name": "love",
        "times": [0.0, 0.25, 0.75, 1.25, 1.7, 2.2, 2.75],
        "right": ["rest", "rest", "love_chest", "love_chest", "love_forward", "love_forward", "rest"],
        "right_curl": [0.0, 0.0, 0.0, 0.0, 0.45, 0.45, 0.0],
    },
    {
        "name": "pain",
        "times": [0.0, 0.3, 0.85, 1.25, 1.65, 2.1, 2.75, 3.2],
        "right": ["rest", "rest", "pain", "pain", "pain", "pain", "rest", "rest"],
        "right_curl": [0.0, 0.0, 0.25, 0.8, 0.25, 0.8, 0.0, 0.0],
    },
    {
        "name": "angry",
        "times": [0.0, 0.3, 0.75, 1.2, 1.65, 2.25, 2.9, 3.35],
        "right": ["rest", "rest", "angry_chest", "angry_chest", "angry_face", "angry_face", "rest", "rest"],
        "right_curl": [0.0, 0.0, 0.8, 0.8, 0.2, 0.2, 0.0, 0.0],
    },
    {
        "name": "bank",
        "times": [0.0, 0.3, 0.85, 1.35, 1.85, 2.35, 2.85],
        "right": ["rest", "rest", "bank_r", "bank_r", "bank_r", "rest", "rest"],
        "left": ["rest", "rest", "bank_l", "bank_l", "bank_l", "rest", "rest"],
        "right_curl": [0.0, 0.0, 0.35, 0.5, 0.35, 0.0, 0.0],
        "left_curl": [0.0, 0.0, 0.35, 0.5, 0.35, 0.0, 0.0],
    },
    {
        "name": "annoyed",
        "times": [0.0, 0.3, 0.8, 1.25, 1.7, 2.15, 2.65],
        "right": ["rest", "rest", "annoyed_upper", "annoyed_upper", "annoyed_lower", "annoyed_lower", "rest"],
        "right_curl": [0.0] * 7,
    },
]

WORDS = {
    "salam_alaykum_full": ["السلام عليكم"],
    "absher_hader": ["أبشر", "حاضر"],
    "love": ["أحبك", "احبك"],
    "pain": ["ألم", "الم"],
    "angry": ["أنا غضبان"],
    "bank": ["بنك"],
    "annoyed": ["تضايق"],
}


def quat_mul(a, b):
    ax, ay, az, aw = a
    bx, by, bz, bw = b
    return [
        aw * bx + ax * bw + ay * bz - az * by,
        aw * by - ax * bz + ay * bw + az * bx,
        aw * bz + ax * by - ay * bx + az * bw,
        aw * bw - ax * bx - ay * by - az * bz,
    ]


def euler_xyz(x, y, z):
    cx, sx = math.cos(x / 2), math.sin(x / 2)
    cy, sy = math.cos(y / 2), math.sin(y / 2)
    cz, sz = math.cos(z / 2), math.sin(z / 2)
    return quat_mul(quat_mul([sx, 0.0, 0.0, cx], [0.0, sy, 0.0, cy]), [0.0, 0.0, sz, cz])


def normalize(q):
    length = math.sqrt(sum(value * value for value in q))
    return [value / length for value in q]


def keep_shortest_path(rotations):
    result = [rotations[0]]
    for current in rotations[1:]:
        if sum(a * b for a, b in zip(result[-1], current)) < 0:
            current = [-value for value in current]
        result.append(current)
    return result


def read_glb(path):
    data = path.read_bytes()
    magic, version, _ = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2:
        raise ValueError(f"{path} is not a glTF 2.0 binary file")
    offset = 12
    document = None
    binary = b""
    while offset < len(data):
        length, chunk_type = struct.unpack_from("<II", data, offset)
        offset += 8
        chunk = data[offset : offset + length]
        offset += length
        if chunk_type == JSON_CHUNK:
            document = json.loads(chunk.decode("utf-8").rstrip("\x00 "))
        elif chunk_type == BIN_CHUNK:
            binary = chunk
    if document is None:
        raise ValueError(f"{path} has no JSON chunk")
    return document, bytearray(binary)


def append_floats(document, binary, values, accessor_type, minimum=None, maximum=None):
    while len(binary) % 4:
        binary.append(0)
    byte_offset = len(binary)
    flat = [component for value in values for component in value]
    binary.extend(struct.pack(f"<{len(flat)}f", *flat))
    view_index = len(document.setdefault("bufferViews", []))
    document["bufferViews"].append({"buffer": 0, "byteOffset": byte_offset, "byteLength": len(flat) * 4})
    accessor = {"bufferView": view_index, "componentType": FLOAT, "count": len(values), "type": accessor_type}
    if minimum is not None:
        accessor["min"] = minimum
    if maximum is not None:
        accessor["max"] = maximum
    accessor_index = len(document.setdefault("accessors", []))
    document["accessors"].append(accessor)
    return accessor_index


def find_node(document, name):
    for index, node in enumerate(document.get("nodes", [])):
        if node.get("name") == name:
            return index
    raise KeyError(f"Missing bone: {name}")


def rotations_from_poses(document, node_name, poses, offset):
    node_index = find_node(document, node_name)
    base = document["nodes"][node_index].get("rotation", [0.0, 0.0, 0.0, 1.0])
    rotations = []
    for pose_name in poses:
        pose = POSES[pose_name]
        rotations.append(normalize(quat_mul(base, euler_xyz(*pose[offset : offset + 3]))))
    return keep_shortest_path(rotations)


def rotations_from_curl(document, node_name, weights, angle):
    node_index = find_node(document, node_name)
    base = document["nodes"][node_index].get("rotation", [0.0, 0.0, 0.0, 1.0])
    rotations = [normalize(quat_mul(base, euler_xyz(angle * weight, 0.0, 0.0))) for weight in weights]
    return keep_shortest_path(rotations)


def animation_tracks(document, spec):
    tracks = []
    for side, key in (("R", "right"), ("L", "left")):
        poses = spec.get(key)
        curls = spec.get(f"{key}_curl")
        if poses is None:
            continue
        tracks.extend([
            (f"DEF-upper_arm.{side}", rotations_from_poses(document, f"DEF-upper_arm.{side}", poses, 0)),
            (f"DEF-forearm.{side}", rotations_from_poses(document, f"DEF-forearm.{side}", poses, 3)),
            (f"DEF-hand.{side}", rotations_from_poses(document, f"DEF-hand.{side}", poses, 6)),
        ])
        if curls is None:
            continue
        for finger in ("index", "middle", "ring", "pinky"):
            for segment, angle in (("01", 1.10), ("02", 1.25), ("03", 0.95)):
                name = f"DEF-f_{finger}.{segment}.{side}"
                tracks.append((name, rotations_from_curl(document, name, curls, angle)))
        for segment, angle in (("01", 0.55), ("02", 0.75), ("03", 0.55)):
            name = f"DEF-thumb.{segment}.{side}"
            tracks.append((name, rotations_from_curl(document, name, curls, angle)))
    return tracks


def build_animation(document, binary, spec):
    times = spec["times"]
    time_accessor = append_floats(document, binary, [(value,) for value in times], "SCALAR", [times[0]], [times[-1]])
    samplers = []
    channels = []
    tracks = animation_tracks(document, spec)
    for name, rotations in tracks:
        output_accessor = append_floats(document, binary, rotations, "VEC4")
        sampler_index = len(samplers)
        samplers.append({"input": time_accessor, "output": output_accessor, "interpolation": "LINEAR"})
        channels.append({"sampler": sampler_index, "target": {"node": find_node(document, name), "path": "rotation"}})
    return {"name": spec["name"], "samplers": samplers, "channels": channels}


def frame_data(spec, index):
    duration = spec["times"][-1]
    frame = {"frame": round((spec["times"][index] / duration) * 100)}
    right_pose = POSES[spec["right"][index]]
    right_curl = spec.get("right_curl", [0.0] * len(spec["times"]))[index]
    frame.update({
        "upper_arm_rot": right_pose[0:3],
        "forearm_rot": right_pose[3:6],
        "hand_rot": right_pose[6:9],
        "finger_rot": [round(right_curl, 6), 0.0, 0.0],
        "thumb_rot": [round(right_curl * 0.65, 6), 0.0, 0.0],
    })
    if "left" in spec:
        left_pose = POSES[spec["left"][index]]
        left_curl = spec.get("left_curl", [0.0] * len(spec["times"]))[index]
        frame.update({
            "left_upper_arm_rot": left_pose[0:3],
            "left_forearm_rot": left_pose[3:6],
            "left_hand_rot": left_pose[6:9],
            "left_finger_rot": [round(left_curl, 6), 0.0, 0.0],
            "left_thumb_rot": [round(left_curl * 0.65, 6), 0.0, 0.0],
        })
    return frame


def write_dictionary(root):
    dictionary = {}
    for spec in ANIMATIONS:
        words = WORDS[spec["name"]]
        entry = {
            "animationName": spec["name"],
            "durationMs": round(spec["times"][-1] * 1000),
            "frames": [frame_data(spec, index) for index in range(len(spec["times"]))],
        }
        for word in words:
            dictionary[word] = entry
    output_path = root / "assets" / "signs" / "sign_motion_dictionary.json"
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(dictionary, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Created {output_path} with {len(dictionary)} words")


def write_glb(source, destination):
    document, binary = read_glb(source)
    document["animations"] = [build_animation(document, binary, spec) for spec in ANIMATIONS]
    document["buffers"][0]["byteLength"] = len(binary)
    json_bytes = json.dumps(document, ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    json_bytes += b" " * ((4 - len(json_bytes) % 4) % 4)
    binary += b"\x00" * ((4 - len(binary) % 4) % 4)
    total_length = 12 + 8 + len(json_bytes) + 8 + len(binary)
    output = bytearray(struct.pack("<4sII", b"glTF", 2, total_length))
    output.extend(struct.pack("<II", len(json_bytes), JSON_CHUNK))
    output.extend(json_bytes)
    output.extend(struct.pack("<II", len(binary), BIN_CHUNK))
    output.extend(binary)
    destination.write_bytes(output)
    print(f"Created {destination} with {len(document['animations'])} animations")


def main():
    root = Path(__file__).resolve().parents[1]
    avatar_dir = root / "assets" / "web_avatar"
    for source_name, destination_name in (("Salman_sign.glb", "Salman_salam.glb"), ("Najd_sign.glb", "Najd_salam.glb")):
        write_glb(avatar_dir / source_name, avatar_dir / destination_name)
    write_dictionary(root)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(f"Animation build failed: {error}", file=sys.stderr)
        raise
