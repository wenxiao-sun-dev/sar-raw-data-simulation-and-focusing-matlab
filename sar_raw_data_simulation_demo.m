% sar_raw_data_simulation_demo.m
clear; close all; clc;

% Physical constant
c = 3e8;

% Radar parameters
radarParams.wavelength = 0.03;        % [m]
radarParams.platformHeight = 2000;    % [m]
radarParams.platformVelocity = 100;   % [m/s]
radarParams.incidenceAngle = pi/6;    % [rad]
radarParams.antennaLength = 1;        % [m]
radarParams.bandwidth = 150e6;        % [Hz]
radarParams.pulseDuration = 5e-6;     % [s]
radarParams.sampleRate = 180e6;       % [Hz]
radarParams.reflectivity = 1;

% Point target position
targetPosition.x = 0;
targetPosition.y = radarParams.platformHeight / tan(radarParams.incidenceAngle);
targetPosition.z = 0;

% Reference slant range
referenceRange = sqrt(targetPosition.y^2 + radarParams.platformHeight^2);

% Synthetic aperture time and PRF
syntheticApertureTime = referenceRange * radarParams.wavelength / ...
    (radarParams.antennaLength * radarParams.platformVelocity);
pulseRepetitionFrequency = 4 * radarParams.platformVelocity / radarParams.antennaLength;

% Slow-time axis
slowTimeAxis = -3*syntheticApertureTime : 1/pulseRepetitionFrequency : 3*syntheticApertureTime;

% Platform trajectory
platformPosition.x = radarParams.platformVelocity * slowTimeAxis;
platformPosition.y = zeros(size(platformPosition.x));
platformPosition.z = radarParams.platformHeight * ones(size(platformPosition.x));

% Slant range history
rangeHistory = sqrt( ...
    (targetPosition.x - platformPosition.x).^2 + ...
    (targetPosition.y - platformPosition.y).^2 + ...
    (targetPosition.z - platformPosition.z).^2);

% Direction cosine and antenna weighting
directionCosine = (targetPosition.x - platformPosition.x) ./ rangeHistory;
antennaWeight = sinc(directionCosine * radarParams.antennaLength / radarParams.wavelength).^2;

% Azimuth axis
azimuthAxis = slowTimeAxis * radarParams.platformVelocity;

% Range axis
minRange = min(rangeHistory);
maxRange = max(rangeHistory);

rangeAxis = minRange - 100 : (c / (2 * radarParams.sampleRate)) : ...
    maxRange + radarParams.pulseDuration * c / 2 + 100;

fastTimeAxis = 2 * rangeAxis / c;

numRangeSamples = length(fastTimeAxis);
numAzimuthSamples = length(slowTimeAxis);

% Raw SAR data matrix
rawData = zeros(numRangeSamples, numAzimuthSamples);

% Simulate raw SAR data
for azIdx = 1:numAzimuthSamples
    currentRange = rangeHistory(azIdx);
    currentAntennaWeight = antennaWeight(azIdx);

    timeShiftedPulse = generate_rect_window( ...
        fastTimeAxis, ...
        radarParams.pulseDuration/2 + 2*currentRange/c, ...
        radarParams.pulseDuration);

    chirpPhase = exp(1j * pi * radarParams.bandwidth / radarParams.pulseDuration * ...
        (fastTimeAxis - radarParams.pulseDuration/2 - 2*currentRange/c).^2);

    propagationPhase = exp(-1j * 4*pi/radarParams.wavelength * currentRange);

    rawData(:, azIdx) = radarParams.reflectivity ...
        * currentAntennaWeight ...
        * propagationPhase ...
        .* timeShiftedPulse ...
        .* chirpPhase;
end

% Display raw data
figure;
imagesc(azimuthAxis, rangeAxis, 20*log10(abs(rawData) + eps) - max(20*log10(abs(rawData(:)) + eps)));
title('Simulated SAR Raw Data');
xlabel('Azimuth (m)');
ylabel('Range (m)');
caxis([-40 0]);
colorbar;
axis xy;

% Save useful variables for the focusing script
save('sar_simulated_data.mat', ...
    'rawData', ...
    'rangeAxis', ...
    'azimuthAxis', ...
    'slowTimeAxis', ...
    'pulseRepetitionFrequency', ...
    'syntheticApertureTime', ...
    'referenceRange', ...
    'radarParams');