clear all; 
close all; 
clc;

% -------- Load Input Audio --------
% Drum+Bass = mixture signal
% Bell = external signal to insert
[x, fs] = audioread('Drum+Bass.wav');
[y, fy] = audioread('Bell.wav');

% -------- STFT Parameters --------
FFTSIZE = 1024;     % FFT length
HOPSIZE = 256;      % Frame shift
WINDOWSIZE = 512;   % Analysis window length

% Compute STFT of mixture and bell
X = myspectrogram(x, FFTSIZE, fs, hann(WINDOWSIZE), -HOPSIZE);
Y = myspectrogram(y, FFTSIZE, fs, hann(WINDOWSIZE), -HOPSIZE);

% Use only magnitude (positive frequencies) for NMF
V = abs(X(1:(FFTSIZE/2+1), :));

% -------- NMF Decomposition --------
K = 4;          % Number of sources to extract
MAXITER = 100;  % Iterations for convergence

% Factorize magnitude spectrogram: V ≈ W * H
[W, H] = nmf(V, K, MAXITER);

% Store original phase for reconstruction
phi_full = angle(X);

% -------- Reconstruct Each Separated Source --------
inst = cell(1,4);

for i = 1:4
    
    % Rebuild magnitude of ith component
    XmagHat = W(:,i) * H(i,:);
    
    % Recreate full spectrum (conjugate symmetry)
    XmagHat = [XmagHat; conj(XmagHat(end-1:-1:2,:))];
    
    % Combine estimated magnitude with original phase
    Xhat = XmagHat .* exp(1i * phi_full);
    
    % Convert back to time domain (ISTFT)
    inst{i} = real(invmyspectrogram(Xhat, HOPSIZE));
    inst{i} = inst{i}(1:length(x))';
    
    % RMS normalization to control loudness
    rms_val = rms(inst{i});
    if rms_val > 0
        inst{i} = inst{i} / rms_val * 0.3;
    end
end

% -------- Bell Reconstruction Using Mixture Phase --------
Ymag = abs(Y(1:(FFTSIZE/2+1), 1:size(phi_full,2)));
Ymag_full = [Ymag; conj(Ymag(end-1:-1:2,:))];

Yhat = Ymag_full .* exp(1i * phi_full);

bell = real(invmyspectrogram(Yhat, HOPSIZE));
bell = bell(1:length(x))';
bell = bell / rms(bell) * 0.3;

% -------- Final Mix --------
audio_final = inst{1} + inst{2} + inst{3} + inst{4} + bell;

% Play final result
soundsc(audio_final, fs);

fprintf('Press any key to play individual components...\n');
pause;

% Play separated sources
soundsc(inst{1}, fs); pause;
soundsc(inst{2}, fs); pause; 
soundsc(inst{3}, fs); pause;
soundsc(inst{4}, fs); pause;
soundsc(bell, fs); pause;

% -------- Save Audio Results --------
if ~exist('audio','dir')
    mkdir('audio');
end

if ~exist('results','dir')
    mkdir('results');
end

% Save final mix
audiowrite(fullfile('audio','mixed_signal.wav'), audio_final, fs);

% Save separated components
audiowrite(fullfile('results','source1.wav'), inst{1}, fs);
audiowrite(fullfile('results','source2.wav'), inst{2}, fs);
audiowrite(fullfile('results','source3.wav'), inst{3}, fs);
audiowrite(fullfile('results','source4.wav'), inst{4}, fs);
audiowrite(fullfile('results','bell.wav'), bell, fs);

% -------- Spectrogram Visualization --------
figure;

subplot(6,1,1);
spectrogram(audio_final, hamming(1024), 512, 1024, fs, 'yaxis');
title('Final Mixed Signal');

subplot(6,1,2);
spectrogram(inst{1}, hamming(1024), 512, 1024, fs, 'yaxis');
title('Separated Source 1');

subplot(6,1,3);
spectrogram(inst{2}, hamming(1024), 512, 1024, fs, 'yaxis');
title('Separated Source 2');

subplot(6,1,4);
spectrogram(inst{3}, hamming(1024), 512, 1024, fs, 'yaxis');
title('Separated Source 3');

subplot(6,1,5);
spectrogram(inst{4}, hamming(1024), 512, 1024, fs, 'yaxis');
title('Separated Source 4');

subplot(6,1,6);
spectrogram(bell, hamming(1024), 512, 1024, fs, 'yaxis');
title('Reconstructed Bell');

colormap jet;

% Save comparison figure
saveas(gcf, fullfile('results','separation_comparison.png'));

% -------- Energy Comparison --------
orig_energy = sum(audio_final.^2);
sep_energy = sum(inst{1}.^2 + inst{2}.^2 + inst{3}.^2 + inst{4}.^2 + bell.^2);

disp(['Final Mix Energy: ', num2str(orig_energy)]);
disp(['Sum of Separated Energies: ', num2str(sep_energy)]);
disp('Results saved in audio/ and results/ folders.');
