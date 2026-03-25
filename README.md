# OFDM Communications System Simulation
### ECE Resume Project — MATLAB (No Communications Toolbox Required)

---

## Overview

A complete OFDM (Orthogonal Frequency Division Multiplexing) transceiver simulation built from scratch in MATLAB. This project implements the same core technology used in **WiFi (802.11a/g/n)**, **4G LTE**, and **5G NR** — without requiring any paid toolboxes.

All Communications Toolbox functions (`qammod`, `qamdemod`, `bi2de`, `de2bi`, `awgn`, `berawgn`) have been reimplemented as local helper functions using pure MATLAB math.

---

## Requirements

| Tool | Version |
|---|---|
| MATLAB | R2020b or later (tested on R2025b) |
| Signal Processing Toolbox | For `spectrogram()` in Milestone 6 |

> **No Communications Toolbox needed.** All modulation, demodulation, noise, and BER functions are implemented from scratch.

---

## How to Run

1. Open `ofdm_project.m` in MATLAB or MATLAB Online
2. Press **Run** (F5) to execute the full simulation top to bottom
3. Or press **Ctrl+Enter** (Cmd+Enter on Mac) to run individual sections one at a time

The script prints progress to the Command Window and generates 5 figures automatically.

---

## Project Structure

```
ofdm_project.m
│
├── System Parameters        — N_fft, N_cp, M, SNR range
│
├── Milestone 1 — QAM Modulation
│     Bits → QAM symbols, constellation diagram
│
├── Milestone 2 — OFDM Transmitter
│     Symbols → IFFT → add cyclic prefix → serial stream
│
├── Milestone 3 — Channel Model
│     Multipath convolution + AWGN noise injection
│
├── Milestone 4 — OFDM Receiver
│     Remove CP → FFT → zero-forcing equalization → bits
│
├── Milestone 5 — BER vs SNR Sweep
│     Sweep SNR from -5 to 30 dB, compute BER at each point
│
├── Milestone 6 — Spectrogram
│     Time-frequency visualization of the OFDM signal
│
├── Bonus — Modulation Comparison
│     Overlay QPSK / 16-QAM / 64-QAM BER curves
│
└── Helper Functions (bottom of file)
      qam_mod, qam_demod, bits2int_msb, int2bits_msb,
      add_awgn, qam_ber_theory
```

---

## Output Plots

| Figure | What you see |
|---|---|
| M1 — Constellation | Clean QAM grid vs noisy scatter at 15 dB SNR |
| M4 — Equalization | Received symbols before and after zero-forcing equalizer |
| M5 — BER vs SNR | Simulated BER curve vs theoretical AWGN limit |
| M6 — Spectrogram | Time-frequency heatmap of the transmitted signal |
| Bonus — Comparison | QPSK / 16-QAM / 64-QAM BER curves on one plot |

---

## Key Parameters to Experiment With

```matlab
N_fft = 64;       % Try 128 or 256 — more subcarriers, closer to real LTE
N_cp  = 16;       % Try 8 — watch BER worsen as CP no longer covers delay
M     = 16;       % Try 4 (QPSK) or 64 (64-QAM) — trade speed vs robustness
```

**What changes when you increase M:**
- More bits per symbol → higher data rate
- Constellation points are closer together → needs higher SNR to decode correctly
- BER curve shifts right on the plot

**What changes when you set `path_gains = [1, 0, 0]`:**
- No multipath — simulated BER matches theory almost exactly
- Gap between simulated and theoretical curve disappears

---

## System Design

### Transmitter chain
```
Random bits → QAM modulate → reshape into N_fft × N_sym matrix
→ IFFT (freq domain to time domain) → prepend cyclic prefix → transmit
```

### Channel
```
Transmitted signal → convolve with multipath impulse response
→ add AWGN noise
```

### Receiver chain
```
Received signal → reshape → remove cyclic prefix → FFT
→ zero-forcing equalization (divide by channel response)
→ QAM demodulate → bits → compare with TX bits → BER
```

### Why the cyclic prefix works
The cyclic prefix (CP) converts linear convolution (caused by multipath) into circular convolution. This means the FFT at the receiver perfectly undoes the channel effect with a simple pointwise division — no matrix inversion needed.

---

## Helper Functions Reference

| Function | Replaces | What it does |
|---|---|---|
| `qam_mod(indices, M)` | `qammod()` | Gray-coded QAM, unit average power |
| `qam_demod(syms, M)` | `qamdemod()` | Minimum distance decoder |
| `bits2int_msb(matrix, k)` | `bi2de()` | Bit rows → integer indices |
| `int2bits_msb(indices, k)` | `de2bi()` | Integer indices → bit rows |
| `add_awgn(signal, snr_dB)` | `awgn()` | Adds proper complex Gaussian noise |
| `qam_ber_theory(snr_dB, M)` | `berawgn()` | Theoretical BER using erfc() |

---

## Resume Description

> Designed and simulated a complete OFDM transceiver in MATLAB implementing Gray-coded QAM modulation (QPSK to 64-QAM), IFFT/FFT-based subcarrier multiplexing, cyclic prefix insertion, 3-tap multipath channel modeling, zero-forcing equalization, and BER vs SNR characterization — all without Communications Toolbox dependencies.

---

## Real-World Connections

| This project | Real system |
|---|---|
| `N_fft = 64`, `N_cp = 16` | WiFi 802.11a (exact same parameters) |
| `M = 64` (64-QAM) | Used in WiFi when you're close to the router |
| `M = 4` (QPSK) | Used in LTE control channels, more robust |
| BER vs SNR curve | How engineers benchmark modems at Qualcomm / MediaTek |
| Zero-forcing equalizer | Simplest form of the equalizer inside every WiFi chip |

---

*Built for ECE students targeting roles in wireless communications, DSP, and semiconductor engineering.*
