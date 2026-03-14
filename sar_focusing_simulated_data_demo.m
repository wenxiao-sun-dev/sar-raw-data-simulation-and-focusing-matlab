% sar_focusing_simulated_data_demo.m
clear; close all; clc;

% Load simulated SAR raw data
loadedData = load('sar_simulated_data.mat');

rawData = loadedData.rawData;
rangeAxis = loadedData.rangeAxis;
azimuthAxis = loadedData.azimuthAxis;
pulseRepetitionFrequency = loadedData.pulseRepetitionFrequency;
syntheticApertureTime = loadedData.syntheticApertureTime;
referenceRange = loadedData.referenceRange;
radarParams = loadedData.radarParams;

numRangeSamples = size(rawData, 1);
numAzimuthSamples = size(rawData, 2);

% Display raw data
figure;
imagesc(azimuthAxis, rangeAxis, 20*log10(abs(rawData) + eps) - max(20*log10(abs(rawData(:)) + eps)));
title('Raw SAR Data');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

%% Range compression
rangeSpectrum = fft(rawData, [], 1);

referenceTime = 0 : 1/radarParams.sampleRate : radarParams.pulseDuration;
rangeReferenceSignal = exp(1j * pi * radarParams.bandwidth / radarParams.pulseDuration * ...
    (referenceTime - radarParams.pulseDuration/2).^2);

rangeReferenceSpectrum = fft(rangeReferenceSignal, numRangeSamples);
matchedRangeSpectrum = rangeSpectrum .* conj(rangeReferenceSpectrum.' * ones(1, numAzimuthSamples));
rangeCompressedData = ifft(matchedRangeSpectrum, [], 1);

% Display range-compressed data
figure;
imagesc(azimuthAxis, rangeAxis, ...
    20*log10(abs(rangeCompressedData) + eps) - max(20*log10(abs(rangeCompressedData(:)) + eps)));
title('Range-Compressed SAR Data');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

%% Azimuth compression
azimuthSpectrum = fft(rangeCompressedData, [], 2);

azimuthReferenceTime = -syntheticApertureTime/2 : 1/pulseRepetitionFrequency : syntheticApertureTime/2;
azimuthReferenceSignal = exp(-1j * pi * 2 * radarParams.platformVelocity^2 ...
    * azimuthReferenceTime.^2 / (radarParams.wavelength * referenceRange));

azimuthReferenceSpectrum = fft(azimuthReferenceSignal, numAzimuthSamples);

matchedAzimuthSpectrum = azimuthSpectrum .* conj(ones(numRangeSamples, 1) * azimuthReferenceSpectrum);

dopplerAxis = (0:numAzimuthSamples-1) / numAzimuthSamples * pulseRepetitionFrequency;
azimuthShift = exp(-1j * 2*pi * dopplerAxis * syntheticApertureTime/2);

matchedAzimuthSpectrumShifted = matchedAzimuthSpectrum .* (ones(numRangeSamples, 1) * azimuthShift);

focusedImage = ifft(matchedAzimuthSpectrumShifted, [], 2);

% Display focused image
figure;
imagesc(azimuthAxis, rangeAxis, ...
    20*log10(abs(focusedImage) + eps) - max(20*log10(abs(focusedImage(:)) + eps)));
title('Focused SAR Image');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;