% sar_focusing_dataset_demo.m
clear; close all; clc;

% Example:
% Replace 'data.mat' with dataset.
dataFilename = 'data.mat';

loadedData = load(dataFilename);
rawData = loadedData.data;
radarParams = loadedData.p;

% Estimate reference range
referenceRange = mean(radarParams.vec_range);

% Display raw data
figure;
imagesc(radarParams.vec_azimuth, radarParams.vec_range, ...
    20*log10(abs(rawData) + eps) - max(20*log10(abs(rawData(:)) + eps)));
title('Input SAR Dataset');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

% Synthetic aperture time
syntheticApertureTime = referenceRange * radarParams.lambda / ...
    (radarParams.L * radarParams.vplat);

numRangeSamples = size(rawData, 1);
numAzimuthSamples = size(rawData, 2);

%% Range compression
rangeSpectrum = fft(rawData, [], 1);

rangeReferenceSignal = radarParams.ref_range;
rangeReferenceSpectrum = fft(rangeReferenceSignal, numRangeSamples);

matchedRangeSpectrum = rangeSpectrum .* conj(rangeReferenceSpectrum * ones(1, numAzimuthSamples));
rangeCompressedData = ifft(matchedRangeSpectrum, [], 1);

figure;
imagesc(radarParams.vec_azimuth, radarParams.vec_range, ...
    20*log10(abs(rangeCompressedData) + eps) - max(20*log10(abs(rangeCompressedData(:)) + eps)));
title('Range-Compressed Dataset');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

%% Azimuth compression
azimuthSpectrum = fft(rangeCompressedData, [], 2);

azimuthReferenceTime = -syntheticApertureTime/2 : 1/radarParams.PRF : syntheticApertureTime/2;
azimuthReferenceSignal = exp(-1j * pi * 2 * radarParams.vplat^2 ...
    * azimuthReferenceTime.^2 / (radarParams.lambda * referenceRange));

azimuthReferenceSpectrum = fft(azimuthReferenceSignal, numAzimuthSamples);

matchedAzimuthSpectrum = azimuthSpectrum .* conj(ones(numRangeSamples, 1) * azimuthReferenceSpectrum);

dopplerAxis = (0:numAzimuthSamples-1) / numAzimuthSamples * radarParams.PRF;
azimuthShift = exp(-1j * 2*pi * dopplerAxis * syntheticApertureTime/2);

matchedAzimuthSpectrumShifted = matchedAzimuthSpectrum .* (ones(numRangeSamples, 1) * azimuthShift);

focusedImage = ifft(matchedAzimuthSpectrumShifted, [], 2);

figure;
imagesc(radarParams.vec_azimuth, radarParams.vec_range, ...
    20*log10(abs(focusedImage) + eps) - max(20*log10(abs(focusedImage(:)) + eps)));
title('Focused SAR Image from Dataset');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

%% Optional display adjustment
focusedImageShifted = ifftshift(focusedImage, 1);

figure;
imagesc(radarParams.vec_azimuth, radarParams.vec_range, ...
    20*log10(abs(focusedImageShifted) + eps) - max(20*log10(abs(focusedImageShifted(:)) + eps)));
title('Focused SAR Image (Shifted)');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;