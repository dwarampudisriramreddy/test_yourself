# AI Quiz (testai)

Offline, on-device quiz generator for Android. It uses `flutter_gemma` +
`flutter_gemma_litertlm` (LiteRT-LM engine) to run a small LLM directly on the
phone and generate a multiple-choice quiz as strict JSON in a single inference.
No network connection and no API key are needed after the one-time model download.

## Project structure

```
lib/
  main.dart                      Engine init + app entry
  models/quiz.dart               Quiz / QuizQuestion + tolerant JSON parsing
  services/quiz_generator.dart   Model download/load + single-inference generation
  screens/
    home_screen.dart             Topic, difficulty, question count -> GENERATE QUIZ
    quiz_screen.dart             One question at a time, A-D options, explanations
    result_screen.dart           Score, % , restart
android/app/src/main/AndroidManifest.xml   Permissions, OpenCL libs, foreground service
```

## Prerequisites

- Flutter **3.47.0+** (Dart >= 3.12, required by `flutter_gemma_litertlm`)
- Android device with **arm64-v8a** CPU (the LiteRT-LM native libs are
  arm64-only; a 64-bit phone or emulator is required)
- minSdk **24** or higher
- ~600 MB free storage for the default model + app

## Build & run (Termux / Linux shell)

```bash
# 1. Fetch dependencies
flutter pub get

# 2. Run on a connected device / emulator (default model: Qwen3 0.6B, public, GPU-first)
flutter run --dart-define=MODEL_TYPE=qwen3

# 3. Build a release APK
flutter build apk --release
# APK output: build/app/outputs/flutter-apk/app-release.apk
```

First launch downloads the model (~586 MB) with a progress bar, then everything
is offline.

## Model configuration (compile-time `--dart-define`)

| Define | Default | Purpose |
| --- | --- | --- |
| `MODEL_URL` | Qwen3 0.6B `.litertlm` (public) | Hugging Face download URL (**must end in `.litertlm`**) |
| `MODEL_TYPE` | `qwen3` | `qwen3` \| `qwen` \| `gemma` \| `general` |
| `HUGGINGFACE_TOKEN` | *(empty)* | Only for gated repos (e.g. Gemma 3 1B) |

> **Important:** the LiteRT-LM engine can only load `.litertlm` files. `.task` /
> `.tflite` models (e.g. the `.task` variants of Qwen 2.5, or DeepSeek R1, which
> has no `.litertlm` build) are not supported and will fail with a clear message.
> If you see `No inference engine can handle this model (ModelFileType.task)`,
> your `MODEL_URL` points at a `.task` file — switch it to the `.litertlm`
> filename in the same repo.

Default model (public, no token, officially GPU-benchmarked on Android):
`litert-community/Qwen3-0.6B` (`Qwen3-0.6B.litertlm`, ~586 MB).

Examples:

```bash
# Qwen 2.5 1.5B (bigger/more capable, CPU-friendly, public)
flutter run --dart-define=MODEL_TYPE=qwen \
  --dart-define=MODEL_URL=https://huggingface.co/litert-community/Qwen2.5-1.5B-Instruct/resolve/main/Qwen2.5-1.5B-Instruct_multi-prefill-seq_q8_ekv4096.litertlm

# Gemma 3 1B IT (gated: request access first)
flutter run --dart-define=MODEL_TYPE=gemma \
  --dart-define=MODEL_URL=https://huggingface.co/litert-community/Gemma3-1B-IT/resolve/main/Gemma3-1B-IT_multi-prefill-seq_q4_ekv4096.litertlm \
  --dart-define=HUGGINGFACE_TOKEN=hf_...
```

To use Gemma 3 1B IT, first request access at
<https://huggingface.co/litert-community/Gemma3-1B-IT> and set your token.

## GPU / backend notes (Android)

- The LiteRT-LM GPU backend on Android uses **OpenCL** (`libOpenCL.so`).
- Works well on devices with native OpenCL drivers (Qualcomm Adreno, most Mali).
- **Pixel 8/9 (Tensor G3/G4)** do not expose OpenCL -> GPU init fails; the app
  automatically falls back to CPU. Some newer Exynos devices (ANGLE-CL) also
  fail GPU init and fall back to CPU.
- To build for release, keep `ndk { abiFilters += listOf("arm64-v8a") }` in
  `android/app/build.gradle.kts`.
