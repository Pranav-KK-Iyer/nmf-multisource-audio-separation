function a = invmyspectrogram(b, hop)

% Get size of spectrogram matrix
[nfft, nframes] = size(b);

No2 = nfft / 2;   % Half FFT size (used for centering)

% Pre-allocate output signal (overlap-add reconstruction)
a = zeros(1, nfft + (nframes-1)*hop);

xoff = 0 - No2;   % Initial offset (centered alignment)

% -------- Main ISTFT Loop --------
for col = 1:nframes
    
    fftframe = b(:,col);     % Take one frequency frame
    
    xzp = ifft(fftframe);    % Convert back to time domain
    
    % Undo zero-phase alignment (reorder samples)
    x = [xzp(nfft-No2+1:nfft); xzp(1:No2)];
    
    % Overlap-add reconstruction
    if xoff < 0
        ix = 1:xoff+nfft;
        a(ix) = a(ix) + x(1-xoff:nfft)';
    else
        ix = xoff+1:xoff+nfft;
        a(ix) = a(ix) + x';
    end
    
    % Move to next frame position
    xoff = xoff + hop;
end

end
