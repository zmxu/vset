function T = ieColorTransform(sensor,targetSpace,illuminant,surface)
% Gateway routine to transform sensor data into a target color space
%
%    T = ieColorTransform(sensor,[targetSpace='XYZ'],[illuminant='D65'],[surface='Macbeth'])
%
% This is a gateway to a collection of methods that find color space
% transformations to map sensor data into a target color space. This
% routine currently has only a few defaults. It will expand over time,
% significantly.  The calling conventions are likely to change, as well.
%
% The default method is to find a linear transformation that maps the the
% sensor responses to the Macbeth ColorChecker into the Macbeth
% ColorChecker values in XYZ under D65 using a least-squares minimization.
% 
% Optionally, the user can send in a spectral file name that contains a
% different surface set (surface) or a file name that contains a
% different illuminant (illuminant).
%
% An alternative is to find the linear transformation that minimizes the
% transformation into linear sRGB values for the Macbeth Color Checker.
% These values are stored in a file.  In the future, we will implement a
% set of linear sRGB values for other sets of surfaces and lights, or at
% least a method of calculating them in here on the fly, and performing
% that minimization.
%
% More elaborate alternatives will be included later.  These are an
% alternative is to minimize a weighted sum of the mean error and the
% noise error.  (Ulrich Barnhoefer, SPIE paper).
%
% We will aso build more complex maps, based on the Manifold methods,
% and return a lookup table for the transformation. (Jeff DiCarlo, JOSA
% paper)
%    
% Examples:
%    sensor = vcGetObject('sensor');
%    T = ieColorTransform(sensor,'XYZ','D65','mcc')
%    T = ieColorTransform(sensor,'Stockman','D65','mcc')
%    T = ieColorTransform(sensor,'linear srgb',[],'mcc')
%    T = ieColorTransform(sensor,'XYZ','D65','esser')
%    T = ieColorTransform(sensor,'XYZ','D65','esser',1)
%
% Copyright ImagEval Consultants, LLC, 2005.

if ieNotDefined('targetSpace'), targetSpace = 'XYZ';     end
if ieNotDefined('illuminant'),  illuminant  = 'D65';     end
if ieNotDefined('surface'),     surface     = 'macbeth'; end

wave     = sensorGet(sensor,'wave');
sensorQE = sensorGet(sensor,'spectralQE');

switch lower(targetSpace)
    case {'stockman','xyz'}
        targetQE = vcReadSpectra(targetSpace,wave);
        
        switch lower(surface)
            case{'mcc','macbeth'}
                T = imageMCCTransform(sensorQE,targetQE,illuminant,wave);
            case {'esser'}
                T = imageEsserTransform(sensorQE,targetQE,illuminant,wave);
        end
        
    case {'linear srgb','lrgb'}
        T = linearsrgb(sensorQE,illuminant,wave);
    case {'sensor'}
        % The internal space is sensor, so we just leave the data alone
        nSensor = sensorGet(sensor,'nSensors');
        T = eye(nSensor,nSensor);
    case 'manifold'
        warning('Not yet implemented -- Returning T = identity'); %#ok<WNTAG>
        T = eye(3,3);
    otherwise
        error('Unknown optimization method.');
end

% Compare the transformed sensor CMF with the internal color space (target)
% CMF
% figure; subplot(1,2,1), plot(sensorQE*T); subplot(1,2,2), plot(targetQE)

return;

%----------------------------------------------
function T = linearsrgb(sensorQE,illuminant,wave)
% Calculate the linear transformation from sensor into linear sRGB values.
%
% We read the MCC values in sRGB space (linear RGB).  The patch order in
% this file is based on ImagEval history, not the official Macbeth
% definition. In the next generation, we will calculate the linear sRGB
% values for the set of surfaces that are sent in.  I think this is fairly
% straightforward and should be implemented soon.

%  TODO
%  Instead of this code, though, we should be using xyz2srgb and then
%  srgb2lrgb.

load('MCClRGB','lrgbValuesMCC','patchOrder');

% Get the MCC surface spectra and the D65 illuminant.  Combine them to
% estimate the sensor responses.
fName = fullfile(isetRootPath,'data','surfaces','macbethChart');

surRef = vcReadSpectra(fName,wave);
surRef = surRef(:,patchOrder);
d65    = vcReadSpectra(illuminant,wave);

sensorMacbeth = (sensorQE'*diag(d65)*surRef)';

% Solve: sensorMacbeth*T = lrgbValuesMCC
T = pinv(sensorMacbeth)*lrgbValuesMCC;

return;
