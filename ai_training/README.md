# Wisal recognition dataset

Record each word at least 10 times, preferably 20 or more, using different
distances, lighting, clothes, backgrounds, and people.

Name repetitions like this:

```text
السلام عليكم__01.mp4
السلام عليكم__02.mp4
احبك__01.mp4
احبك__02.mp4
```

Build the temporal dataset:

```powershell
python ai_training\build_dataset_from_videos.py "C:\path\to\videos" --output ai_training\sequence_dataset.npz
```

Train the model consumed by the server:

```powershell
python ai_training\train_sequence_model.py ai_training\sequence_dataset.npz
```

Upload these files together and restart the Python service:

```text
server/main.py
server/wisal_model.pkl
server/hand_landmarker.task
server/requirements.txt
```
