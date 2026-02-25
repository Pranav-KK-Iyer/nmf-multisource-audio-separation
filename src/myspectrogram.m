function X = myspectrogram(x, nfft, fs, window, noverlap, doplot, dbdown)

% -------- Default parameter handling --------
if nargin<7, dbdown = 100; end
if nargin<6, doplot = 0; end
if nargin<5, noverlap = 256; end
if nargin<3, fs = 1; end
if nargin<2, nfft = 2048; end

x = x(:);                 % Ensure column vector
M = length(window);       % Window length

% Validate window
if (M < 2)
    error('myspectrogram: Expect complete window, now just its length');
end

% Zero-pad if signal is shorter than window
if length(x) < M
    x = [x; zeros(M - length(x), 1)];
end

% -------- Window & hop setup --------
Modd = mod(M,2);
Mo2  = (M - Modd) / 2;    % Half window size
w = window(:);

% Handle overlap / hop size
if noverlap < 0
    nhop = -noverlap;     % Direct hop size
    noverlap = M - nhop;
else
    nhop = M - noverlap;  % Hop size from overlap
end

nx = length(x);
nframes = 1 + ceil(nx / nhop);   % Total number of frames

X = zeros(nfft, nframes);        % Output spectrogram
zp = zeros(nfft - M, 1);         % Zero padding for FFT
xframe = zeros(M,1);

xoff = 0 - Mo2;                  % Frame offset (centered window)

% -------- Main STFT loop --------
for m = 1:nframes
    
    % Extract frame with zero padding at boundaries
    if xoff < 0
        xframe(1:xoff+M) = x(1:xoff+M);
    else
        if xoff + M > nx
            xframe = [x(xoff+1:nx); zeros(xoff+M-nx,1)];
        else
            xframe = x(xoff+1:xoff+M);
        end
    end
    
    % Apply window
    xw = w .* xframe;
    
    % Rearrange for centered FFT (zero-phase alignment)
    xwzp = [xw(Mo2+1:M); zp; xw(1:Mo2)];
    
    % Compute FFT for this frame
    X(:,m) = fft(xwzp);
    
    % Move to next frame
    xoff = xoff + nhop;
end

end
