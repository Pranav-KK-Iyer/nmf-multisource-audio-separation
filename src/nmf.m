function [W, H] = nmf(V, K, MAXITER)

% V  → Magnitude spectrogram (F x T)
% K  → Number of components
% MAXITER → Number of iterations

F = size(V,1);   % Number of frequency bins
T = size(V,2);   % Number of time frames

rand('seed',0)   % Fix random seed for reproducibility

% Initialize W (basis spectra) and H (time activations)
W = 1 + rand(F,K);
H = 1 + rand(K,T);

ONES = ones(F,T);

% -------- Multiplicative Update Loop --------
for i = 1:MAXITER
    
    % Update H (time activations)
    H = H .* (W' * (V ./ (W*H + eps))) ./ (W' * ONES);
    
    % Update W (spectral bases)
    W = W .* ((V ./ (W*H + eps)) * H') ./ (ONES * H');
end

% -------- Normalize W and scale H accordingly --------
sumW = sum(W);
W = W * diag(1 ./ sumW);
H = diag(sumW) * H;

end
