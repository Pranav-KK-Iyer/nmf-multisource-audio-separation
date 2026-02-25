clear all; 
close all; 
clc;

% Read mixture and bell audio
[x fs] = audioread('Drum+Bass.wav');
[y fy] = audioread('Bell.wav');

% STFT parameters
FFTSIZE = 1024;
HOPSIZE = 256;
WINDOWSIZE = 512;

% Compute STFT of both signals
X = myspectrogram(x, FFTSIZE, fs, hann(WINDOWSIZE), -HOPSIZE);
Y = myspectrogram(y, FFTSIZE, fs, hann(WINDOWSIZE), -HOPSIZE);

% Take magnitude of positive frequencies (for NMF)
V = abs(X(1:(FFTSIZE/2+1), :));

% NMF setup
K = 4;          % Number of components to separate
MAXITER = 100;

% Factorize magnitude spectrogram into W (basis) and H (activations)
[W, H] = nmf(V, K, MAXITER);

% Store original phase for reconstruction
phi_full = angle(X);

inst = cell(1,4);

for i = 1:4
    
    % Reconstruct magnitude of ith component
    XmagHat = W(:,i) * H(i,:);
    
    % Rebuild full spectrum using conjugate symmetry
    XmagHat = [XmagHat; conj(XmagHat(end-1:-1:2,:))];
    
    % Combine estimated magnitude with original phase
    Xhat = XmagHat .* exp(1i * phi_full);
    
    % Convert back to time domain (inverse STFT)
    inst{i} = real(invmyspectrogram(Xhat, HOPSIZE));
    inst{i} = inst{i}(1:length(x))';
    
    % Normalize amplitude
    rms_val = rms(inst{i});
    if rms_val > 0
        inst{i} = inst{i} / rms_val * 0.3;
    end
end

% Extract bell magnitude and reconstruct using mixture phase
Ymag = abs(Y(1:(FFTSIZE/2+1), 1:size(phi_full,2)));
Ymag_full = [Ymag; conj(Ymag(end-1:-1:2,:))];
Yhat = Ymag_full .* exp(1i * phi_full);

bell = real(invmyspectrogram(Yhat, HOPSIZE));
bell = bell(1:length(x))';
bell = bell / rms(bell) * 0.3;

% Final mix
audio_final = inst{1} + inst{2} + inst{3} + inst{4} + bell;
soundsc(audio_final, fs);

fprintf('Press any key to play individual components...\n');
pause;

soundsc(inst{1}, fs); pause;
soundsc(inst{2}, fs); pause; 
soundsc(inst{3}, fs); pause;
soundsc(inst{4}, fs); pause;
soundsc(bell, fs); pause;
