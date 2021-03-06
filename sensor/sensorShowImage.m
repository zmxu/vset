function sensorShowImage(ISA,dataType,gam,scaleMax)
% Display the image in a scene structure.
%
%    sensorShowImage(ISA,[dataType='dv'],[gam=1],[scaleMax=0])
%
% The display is shown as a r,g,b or c,m,y or monochrome array that
% indicates the values of individual pixels in the sensor, depending on
% the sensor type. 
%
% This is ordinarily used from within sensorImageWindow, not from the
% command line.  When called from the command line, a new window and axis
% appear.
%
% If digital values have been computed, these are displayed. Otherwise,
% the voltage (continuous) values are displayed. The display gamma
% parameter is read from the figure setting.
%  
% The data are either scaled to a maximum of the voltage swing (default)
% or if scaleMax = 1 (Scale button is selected in the window) the image
% data are scaled to fill up the display range. This option is useful for
% small voltage values compared to the voltage swing, say in the
% simulation of human cone responses. 
%
% Examples:
%   sensorShowImage(sensor,'dv',gam); 
%   sensorShowImage(sensor,'voltage'); 
%
% Copyright ImagEval Consultants, LLC, 2003.

if ieNotDefined('dataType'), dataType = 'dv'; end
if ieNotDefined('gam'),      gam = 1; end
if ieNotDefined('scaleMax'), scaleMax = 0; end

if isempty(ISA), cla;  return; end

% We have the voltage or digital values and we want to render them into an
% image. Here we have to handle various types of cases, include the
% multiple exposure case.
img = sensorData2Image(ISA,dataType,gam,scaleMax);

if ~isempty(img)
    % Show me what you got
    image(img); axis image; axis off;
    if (sensorGet(ISA,'nSensors') == 1), colormap(gray(256)); end
else
    % In this case, there are no volts or dvs, so we just clean up the
    % display
    cla
end


return;