%% ============================================================
%  OFDM Communications System Simulation
%  ECE Resume Project — No Communications Toolbox Required
%  Works with: MATLAB + Signal Processing Toolbox only
%
%  MILESTONES:
%    M1 - QAM Modulation & Constellation
%    M2 - OFDM Transmitter (IFFT + Cyclic Prefix)
%    M3 - Channel Model (AWGN + Multipath)
%    M4 - OFDM Receiver (FFT + Equalization)
%    M5 - BER vs SNR Curve
%    M6 - Spectrogram Visualization
%    BONUS - Compare QPSK / 16-QAM / 64-QAM
%% ============================================================

clear; clc; close all;

%% ============================================================
%  SYSTEM PARAMETERS
%% ============================================================
N_fft        = 64;
N_cp         = 16;
M            = 16;       % QAM order: 4, 16, or 64
N_sym        = 100;
snr_range_dB = -5:2:30;
fs           = 20e6;

k      = log2(M);
N_bits = N_fft * N_sym * k;

fprintf('=== OFDM System Parameters ===\n');
fprintf('Subcarriers   : %d\n', N_fft);
fprintf('Cyclic Prefix : %d samples\n', N_cp);
fprintf('Modulation    : %d-QAM (%d bits/symbol)\n', M, k);
fprintf('OFDM symbols  : %d\n', N_sym);
fprintf('Total bits    : %d\n', N_bits);

%% ============================================================
%  MILESTONE 1 — QAM MODULATION & CONSTELLATION
%% ============================================================
fprintf('\n--- M1: QAM Modulation ---\n');

tx_bits        = randi([0 1], N_bits, 1);
tx_bits_matrix = reshape(tx_bits, [], k);
tx_indices     = bits2int_msb(tx_bits_matrix, k);
tx_symbols     = qam_mod(tx_indices, M);

fprintf('Bits generated    : %d\n', length(tx_bits));
fprintf('Symbols created   : %d\n', length(tx_symbols));
fprintf('Symbol power (avg): %.4f\n', mean(abs(tx_symbols).^2));

figure('Name', 'M1 - QAM Constellation', 'NumberTitle', 'off');
subplot(1,2,1);
plot(real(tx_symbols(1:min(200,end))), imag(tx_symbols(1:min(200,end))), ...
     '.', 'MarkerSize', 10, 'Color', [0.1 0.6 0.4]);
grid on; axis equal;
title(sprintf('%d-QAM Constellation (No Noise)', M));
xlabel('In-phase (I)'); ylabel('Quadrature (Q)');

noisy_syms = add_awgn(tx_symbols, 15);
subplot(1,2,2);
plot(real(noisy_syms(1:min(500,end))), imag(noisy_syms(1:min(500,end))), ...
     '.', 'MarkerSize', 6, 'Color', [0.8 0.4 0.1]);
grid on; axis equal;
title(sprintf('%d-QAM Constellation (SNR = 15 dB)', M));
xlabel('In-phase (I)'); ylabel('Quadrature (Q)');
sgtitle('Milestone 1 — QAM Symbol Mapping');

%% ============================================================
%  MILESTONE 2 — OFDM TRANSMITTER
%% ============================================================
fprintf('\n--- M2: OFDM Transmitter ---\n');

tx_sym_matrix = reshape(tx_symbols, N_fft, N_sym);
ofdm_time     = ifft(tx_sym_matrix, N_fft);
cp            = ofdm_time(end-N_cp+1:end, :);
ofdm_with_cp  = [cp; ofdm_time];
tx_signal     = ofdm_with_cp(:);

fprintf('Samples per symbol (with CP): %d\n', N_fft + N_cp);
fprintf('Total transmitted samples   : %d\n', length(tx_signal));
fprintf('Signal power (avg)          : %.4f\n', mean(abs(tx_signal).^2));

%% ============================================================
%  MILESTONE 3 — CHANNEL MODEL
%% ============================================================
fprintf('\n--- M3: Channel Model ---\n');

snr_demo_dB = 20;
path_delays = [0, 3, 7];
path_gains  = [1, 0.5, 0.25];

h = zeros(max(path_delays)+1, 1);
for p = 1:length(path_delays)
    h(path_delays(p)+1) = path_gains(p);
end

rx_multipath = conv(tx_signal, h, 'same');
rx_signal    = add_awgn(rx_multipath, snr_demo_dB);

fprintf('Channel paths : %d\n', length(path_delays));
fprintf('Max delay     : %d samples\n', max(path_delays));
if N_cp >= max(path_delays)
    fprintf('CP check      : OK — CP covers multipath delay\n');
else
    fprintf('CP check      : WARNING — CP too short!\n');
end

%% ============================================================
%  MILESTONE 4 — OFDM RECEIVER
%% ============================================================
fprintf('\n--- M4: OFDM Receiver ---\n');

rx_matrix    = reshape(rx_signal, N_fft + N_cp, N_sym);
rx_no_cp     = rx_matrix(N_cp+1:end, :);
rx_freq      = fft(rx_no_cp, N_fft);

H_freq       = fft(h, N_fft);
H_freq_mat   = repmat(H_freq, 1, N_sym);
rx_equalized = rx_freq ./ H_freq_mat;

rx_sym_vec   = rx_equalized(:);
rx_indices   = qam_demod(rx_sym_vec, M);
rx_bits_mat  = int2bits_msb(rx_indices, k);
rx_bits      = rx_bits_mat(:);

min_len  = min(length(tx_bits), length(rx_bits));
n_errors = sum(tx_bits(1:min_len) ~= rx_bits(1:min_len));
ber_demo = n_errors / min_len;
fprintf('BER at %d dB SNR : %.5f (%d errors / %d bits)\n', ...
        snr_demo_dB, ber_demo, n_errors, min_len);

figure('Name', 'M4 - Receiver Equalization', 'NumberTitle', 'off');
subplot(1,2,1);
plot(real(rx_freq(:)), imag(rx_freq(:)), '.', ...
     'MarkerSize', 4, 'Color', [0.8 0.2 0.2]);
grid on; axis equal;
title('Before equalization'); xlabel('I'); ylabel('Q');
subplot(1,2,2);
plot(real(rx_equalized(:)), imag(rx_equalized(:)), '.', ...
     'MarkerSize', 4, 'Color', [0.1 0.6 0.4]);
grid on; axis equal;
title('After equalization'); xlabel('I'); ylabel('Q');
sgtitle(sprintf('Milestone 4 — Equalization (SNR = %d dB)', snr_demo_dB));

%% ============================================================
%  MILESTONE 5 — BER vs SNR SWEEP
%% ============================================================
fprintf('\n--- M5: BER vs SNR Sweep ---\n');

ber_sim = zeros(size(snr_range_dB));
ber_th  = qam_ber_theory(snr_range_dB, M);
N_b_ber = N_fft * 200 * k;

for idx = 1:length(snr_range_dB)
    snr  = snr_range_dB(idx);
    bits = randi([0 1], N_b_ber, 1);
    bmat = reshape(bits, [], k);
    syms = qam_mod(bits2int_msb(bmat, k), M);

    sm  = reshape(syms, N_fft, []);
    ot  = ifft(sm, N_fft);
    cpb = ot(end-N_cp+1:end,:);
    ts  = [cpb; ot]; ts = ts(:);
    rmp = conv(ts, h, 'same');
    rs  = add_awgn(rmp, snr);

    rm   = reshape(rs, N_fft+N_cp, []);
    rncp = rm(N_cp+1:end,:);
    rf   = fft(rncp, N_fft);
    req  = rf ./ repmat(H_freq, 1, size(rf,2));
    ridx = qam_demod(req(:), M);
    rb   = int2bits_msb(ridx, k); rb = rb(:);

    ml = min(length(bits), length(rb));
    ber_sim(idx) = sum(bits(1:ml) ~= rb(1:ml)) / ml;
    fprintf('  SNR = %3d dB | BER = %.2e | Theory = %.2e\n', ...
            snr, ber_sim(idx), ber_th(idx));
end

figure('Name', 'M5 - BER vs SNR', 'NumberTitle', 'off');
semilogy(snr_range_dB, ber_th, 'k--', 'LineWidth', 1.5, ...
         'DisplayName', sprintf('%d-QAM Theoretical', M));
hold on;
semilogy(snr_range_dB, max(ber_sim, 1e-6), 'b-o', 'LineWidth', 2, ...
         'MarkerSize', 6, 'DisplayName', sprintf('%d-QAM Simulated', M));
hold off;
grid on;
xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
title(sprintf('BER vs SNR — OFDM %d-QAM, N=%d subcarriers', M, N_fft));
legend('Location', 'southwest');
ylim([1e-6 1]); xlim([snr_range_dB(1) snr_range_dB(end)]);
yline(0.01, 'r:', 'BER = 1%', 'LabelHorizontalAlignment', 'left');

%% ============================================================
%  MILESTONE 6 — SPECTROGRAM
%% ============================================================
fprintf('\n--- M6: Spectrogram ---\n');

figure('Name', 'M6 - Spectrogram', 'NumberTitle', 'off');
[S, F, T] = spectrogram(tx_signal, 64, 48, 128, fs, 'yaxis');
imagesc(T*1e6, F/1e6, 10*log10(abs(S)));
axis xy; colormap('jet'); colorbar;
xlabel('Time (us)'); ylabel('Frequency (MHz)');
title(sprintf('OFDM Spectrogram — %d subcarriers, %d-QAM', N_fft, M));
clim([-60 0]);

%% ============================================================
%  BONUS — COMPARE QPSK / 16-QAM / 64-QAM
%% ============================================================
fprintf('\n--- BONUS: Modulation comparison ---\n');

M_list  = [4, 16, 64];
colors  = {'b', 'g', 'r'};
markers = {'o', 's', '^'};
labels  = {'QPSK (4-QAM)', '16-QAM', '64-QAM'};

figure('Name', 'BONUS - Modulation Comparison', 'NumberTitle', 'off');
hold on;

for mi = 1:length(M_list)
    Mc   = M_list(mi);
    kc   = log2(Mc);
    berc = zeros(size(snr_range_dB));

    for idx = 1:length(snr_range_dB)
        snr  = snr_range_dB(idx);
        Nb   = N_fft * 100 * kc;
        bits = randi([0 1], Nb, 1);
        bmat = reshape(bits, [], kc);
        syms = qam_mod(bits2int_msb(bmat, kc), Mc);
        sm   = reshape(syms, N_fft, []);
        ot   = ifft(sm, N_fft);
        cpb  = ot(end-N_cp+1:end,:);
        ts   = [cpb; ot]; ts = ts(:);
        rmp  = conv(ts, h, 'same');
        rs   = add_awgn(rmp, snr);
        rm   = reshape(rs, N_fft+N_cp, []);
        rncp = rm(N_cp+1:end,:);
        rf   = fft(rncp, N_fft);
        Hf   = fft(h, N_fft);
        req  = rf ./ repmat(Hf, 1, size(rf,2));
        ridx = qam_demod(req(:), Mc);
        rb   = int2bits_msb(ridx, kc); rb = rb(:);
        ml   = min(length(bits), length(rb));
        berc(idx) = sum(bits(1:ml) ~= rb(1:ml)) / ml;
    end

    semilogy(snr_range_dB, max(berc,1e-6), ...
             [colors{mi} '-' markers{mi}], 'LineWidth', 2, ...
             'MarkerSize', 6, 'DisplayName', labels{mi});
    bth = qam_ber_theory(snr_range_dB, Mc);
    semilogy(snr_range_dB, bth, [colors{mi} '--'], ...
             'LineWidth', 1, 'HandleVisibility', 'off');
end

hold off; grid on;
xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
title('BER vs SNR — Modulation Order Comparison');
legend('Location', 'southwest');
ylim([1e-5 1]); xlim([snr_range_dB(1) snr_range_dB(end)]);
yline(0.001, 'k:', '0.1% BER target', 'LabelHorizontalAlignment', 'left');

fprintf('\n=== Simulation Complete ===\n');
fprintf('Plots generated:\n');
fprintf('  1. QAM Constellation (clean vs noisy)\n');
fprintf('  2. Receiver equalization before/after\n');
fprintf('  3. BER vs SNR (simulated vs theoretical)\n');
fprintf('  4. OFDM Spectrogram\n');
fprintf('  5. Multi-modulation BER comparison\n');


%% ============================================================
%  LOCAL HELPER FUNCTIONS
%  (replaces Communications Toolbox functions)
%% ============================================================

function syms = qam_mod(indices, M)
    sqM   = sqrt(M);
    level = -(sqM-1):2:(sqM-1);
    gray  = bitxor(uint32(0:sqM-1), uint32(floor((0:sqM-1)/2)));
    [~, sort_idx] = sort(gray);
    mapped = level(sort_idx);
    scale  = sqrt(2*(M-1)/3);
    I_comp = mapped(mod(indices, sqM) + 1);
    Q_comp = mapped(floor(indices / sqM) + 1);
    syms   = (I_comp(:) + 1j*Q_comp(:)) / scale;
end

function indices = qam_demod(syms, M)
    sqM    = sqrt(M);
    level  = -(sqM-1):2:(sqM-1);
    gray   = bitxor(uint32(0:sqM-1), uint32(floor((0:sqM-1)/2)));
    [~, sort_idx] = sort(gray);
    mapped = level(sort_idx) / sqrt(2*(M-1)/3);
    N      = length(syms);
    I_idx  = zeros(N,1);
    Q_idx  = zeros(N,1);
    Iv     = real(syms(:));
    Qv     = imag(syms(:));
    for n = 1:N
        [~, I_idx(n)] = min(abs(Iv(n) - mapped));
        [~, Q_idx(n)] = min(abs(Qv(n) - mapped));
    end
    indices = (I_idx-1) + sqM*(Q_idx-1);
end

function idx = bits2int_msb(bits_matrix, k)
    powers = 2.^(k-1:-1:0);
    idx    = bits_matrix * powers(:);
end

function bits = int2bits_msb(indices, k)
    N    = length(indices);
    bits = zeros(N, k);
    for b = 1:k
        bits(:,b) = floor(mod(indices, 2^(k-b+1)) / 2^(k-b));
    end
end

function rx = add_awgn(tx, snr_dB)
    sig_power = mean(abs(tx).^2);
    snr_lin   = 10^(snr_dB/10);
    noise_var = sig_power / snr_lin;
    noise     = sqrt(noise_var/2) * (randn(size(tx)) + 1j*randn(size(tx)));
    rx        = tx + noise;
end

function ber = qam_ber_theory(snr_dB, M)
    k_b    = log2(M);
    sqM    = sqrt(M);
    EbN0   = 10.^(snr_dB/10) / k_b;
    ber    = (2*(1-1/sqM)/k_b) .* erfc(sqrt(3*k_b*EbN0 / (2*(M-1))));
end
