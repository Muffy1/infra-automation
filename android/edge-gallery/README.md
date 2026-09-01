# Google AI Edge Gallery — Z Fold Automation Toolkit

Automated install, configuration, model sideloading, and performance tuning for
[Google AI Edge Gallery](https://github.com/google-ai-edge/gallery)
(`com.google.ai.edge.gallery`) on Samsung Galaxy Z Fold devices.

Everything here drives the device over **ADB** — either from a PC/laptop or
**directly on the phone with Termux** (no computer required, see below).

## What's in here

| Script | Purpose |
|---|---|
| `scripts/00-wireless-adb.sh` | Pair + connect over Wi-Fi (no USB cable needed) |
| `scripts/01-install.sh` | Fetch the latest APK from GitHub releases and install it |
| `scripts/02-configure.sh` | Grant permissions, exempt from battery kill, AOT-compile, unlock background limits |
| `scripts/03-models.sh` | Download `.litertlm` / `.task` models from Hugging Face and push them to the phone |
| `scripts/04-zfold-tune.sh` | Z Fold–specific tuning: phantom-process limits, refresh rate, large-screen behavior |
| `scripts/05-benchmark.sh` | Launch the app, capture inference logs, memory and GPU stats |
| `setup.sh` | Runs 01→04 in order (one-shot full setup) |
| `termux/on-device-setup.sh` | The whole flow **from the phone itself** via Termux + loopback wireless debugging |

## Quick start (from a PC)

```bash
# 1. One-time: enable Developer Options on the phone
#    Settings → About phone → Software information → tap "Build number" 7×
#    Then Settings → Developer options → enable "Wireless debugging"

# 2. Pair and connect (follow the prompts)
./scripts/00-wireless-adb.sh

# 3. Full setup: install + configure + models + tune
./setup.sh

# Or run steps individually:
./scripts/01-install.sh
./scripts/02-configure.sh
HF_TOKEN=hf_xxx ./scripts/03-models.sh gemma3-1b   # gated models need a HF token
./scripts/04-zfold-tune.sh
./scripts/05-benchmark.sh
```

## Quick start (no PC — Termux on the Fold itself)

Android 11+ lets the phone ADB into **itself** over loopback. This is the key
trick for doing everything one-handed on the Fold:

1. Install **Termux from F-Droid** (the Play Store build is deprecated and its
   ADB tools are broken): <https://f-droid.org/packages/com.termux/>
2. Enable **Wireless debugging** (Developer options).
3. In split-screen (Fold superpower: Termux on one half, Settings on the other),
   run:

```bash
curl -fsSL https://raw.githubusercontent.com/muffy86/infra-automation/main/android/edge-gallery/termux/on-device-setup.sh | bash
```

The script installs `android-tools`, walks you through pairing against
`localhost`, then runs the same configure/tune steps as the PC flow.

## Importing models into the app

The Gallery reads local models from `/sdcard/Download/`. After
`03-models.sh` pushes a file:

1. Open the app → tap the **"+"** button (bottom-right).
2. Pick the `.litertlm` file from Download.
3. In the import dialog set CPU/GPU preference (use **GPU** on the Fold's
   Adreno — it's dramatically faster for ≥1B-param models) and enable
   *Support image* / *Support audio* for multimodal models.

Curated model sources:
- <https://huggingface.co/litert-community> — official LiteRT conversions
  (Gemma 3 1B, Gemma 3n E2B/E4B, Qwen 2.5, Phi-4 mini, DeepSeek-R1-Distill…)
- Gemma models are **gated**: accept the license on Hugging Face once, then
  pass `HF_TOKEN` to `03-models.sh`.

## Z Fold notes (why `04-zfold-tune.sh` exists)

- **Phantom process killer**: Android 12+ silently kills heavy background
  child processes — the #1 cause of "model stopped mid-generation". The tune
  script disables the monitor and raises the limit.
- **Battery optimization**: Samsung's aggressive app sleeping will deep-sleep
  the Gallery; the script whitelists it (`deviceidle` + `appops`). Also add it
  manually to *Settings → Battery → Background usage limits → Never sleeping
  apps* — that Samsung list has no public ADB knob.
- **AOT compile** (`cmd package compile -m speed`) cuts cold-start time.
- **Thermals**: long inference on the inner screen heats the hinge side; the
  benchmark script logs thermal state so you can see throttling.
- **Cover vs main display**: the app is Compose-based and reflows fine, but if
  it letterboxes on the cover display, *Settings → Display → Full screen apps*
  → enable for Edge Gallery.

## Safety / reversibility

Every system tweak the scripts make is `settings`/`device_config`-level and
reversible; `04-zfold-tune.sh --revert` undoes all of it. Nothing here
requires root, and nothing touches partitions or system files.
