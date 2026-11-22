from pathlib import Path


def ffmpeg_prefix(host_has_ffmpeg, toolbox):
    if host_has_ffmpeg:
        return ["ffmpeg"]
    return ["toolbox", "run", "--container", toolbox, "ffmpeg"]


def extract_audio(video):
    video = Path(video)
    output = video.with_name(f"{video.stem}_audio.m4a")
    return output, ["-i", str(video), "-vn", "-c:a", "copy", str(output)]


def merge_audio(video, audio, bitrate):
    video = Path(video)
    output = video.with_name(f"{video.stem}_denoised.mp4")
    arguments = [
        "-y",
        "-i",
        str(video),
        "-i",
        str(audio),
        "-c:v",
        "copy",
        "-c:a",
        "aac",
        "-b:a",
        bitrate,
        "-map",
        "0:v:0",
        "-map",
        "1:a:0",
        str(output),
    ]
    return output, arguments


def select_clips(names, extensions, output):
    return sorted(
        name
        for name in names
        if Path(name).suffix.lower() in extensions and name != output
    )


def concat_list(folder, clips):
    escaped = (str(Path(folder) / clip).replace("'", "'\\''") for clip in clips)
    return "".join(f"file '{path}'\n" for path in escaped)


def join_arguments(list_path, output):
    return [
        "-y",
        "-f",
        "concat",
        "-safe",
        "0",
        "-i",
        str(list_path),
        "-c",
        "copy",
        str(output),
    ]
