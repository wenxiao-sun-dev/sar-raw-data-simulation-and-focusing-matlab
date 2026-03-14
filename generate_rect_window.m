% generate_rect_window.m
function y = generate_rect_window(timeAxis, centerTime, pulseWidth)
%GENERATE_RECT_WINDOW Generate a rectangular pulse window.
%
% Inputs:
%   timeAxis    - Time vector
%   centerTime  - Center of the rectangular pulse
%   pulseWidth  - Pulse width
%
% Output:
%   y           - Rectangular window

y = zeros(size(timeAxis));
indexInsidePulse = abs(timeAxis - centerTime) <= pulseWidth/2;
y(indexInsidePulse) = 1;

end