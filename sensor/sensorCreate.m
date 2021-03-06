function sensor = sensorCreate(sensorName,PIXEL,varargin)
%Create an image sensor array structure
%
%      sensor = sensorCreate(sensorName,[PIXEL])
%
% The sensor array uses a pixel definition that can be specified in the
% parameter PIXEL. If this is not passed in, a default PIXEL is created and
% returned.
%
% Several type of image sensors can be created, including multispectral and
% a model of the human cone mosaic.
%
%  Bayer RGB combinations
%      {'bayer-grbg'}
%      {'bayer-rggb'}
%      {'bayer-bggr'}
%      {'bayer-gbrg'}
%
%  Bayer CMY combinations
%      {'bayer (ycmy)'}
%      {'bayer (cyym)'}
%
% Other types
%      {'monochrome'}
%
% Multiple channel sensors can be created
%      {'grbc'}
%      {'interleaved'}   - One highly sensitive (transparent) channel and 3 RGB
%      {'fourcolor'}
%      {'custom'}
%
% Human cone mosaic
%      {'human'} - Uses Stockman LMS cones, Bayer array, see
%                  pixelCreate('human'), which returns a 2um aperture
%
% See also: sensorReadColorFilters, sensorCreateIdeal
%
% Examples
%  sensor = sensorCreate;
%  sensor = sensorCreate('default');
%
%  sensor = sensorCreate('bayer (ycmy)');
%  sensor = sensorCreate('bayer (rggb)');
%  sensor = sensorCreate('Monochrome');
%
%  pSize  = 3e-6;
%  sensor = sensorCreate('ideal',[],pSize,'human','bayer');
%
%  cone   = pixelCreate('human cone'); 
%  sensor = sensorCreate('Monochrome',cone);
%  sensor = sensorCreate('human');
%
%  sensor = sensorCreate; pixel = sensorGet(sensor,'pixel');
%  filterOrder = [1 2 3; 4 5 2; 3 1 4];
%  filterFile = fullfile(isetRootPath,'data','sensor','colorfilters','sixChannel.mat');
%  sensor = sensorCreate('custom',pixel,filterOrder,filterFile)
%
%  params.sz = [128,192];
%  params.rgbDensities = [0.1 .6 .2 .1]; % Empty, L,M,S
%  params.coneAperture = [3 3]*1e-6;     % In meters
%  pixel = [];
%  sensor = sensorCreate('human',pixel,params);
%  sensorConePlot(sensor)
%
% Copyright ImagEval Consultants, LLC, 2005

if ieNotDefined('sensorName'), sensorName = 'default'; end

sensor.name = [];
sensor.type = 'sensor';

% Make sure a pixel is defined.
if ieNotDefined('PIXEL')
    PIXEL  = pixelCreate('default');
    sensor = sensorSet(sensor,'pixel',PIXEL);
    sensor = sensorSet(sensor,'size',sensorFormats('qqcif'));
else
    sensor = sensorSet(sensor,'pixel',PIXEL);
end

% The sensor should always inherit the spectrum of the pixel.  Probably
% there should only be one spectrum here, not one for pixel and sensor.
sensor = sensorSet(sensor,'spectrum',pixelGet(PIXEL,'spectrum'));

sensor = sensorSet(sensor,'data',[]);

sensor = sensorSet(sensor,'sigmagainfpn',0);    % [V/A]  This is the slope of the transduction function
sensor = sensorSet(sensor,'sigmaoffsetfpn',0);  % V      This is the offset from 0 volts after reset

% I wonder if the default spectrum should be hyperspectral, or perhaps it
% should be inherited from the currently selected optical image?
% sensor = initDefaultSpectrum(sensor,'hyperspectral');

sensor = sensorSet(sensor,'analogGain',1);
sensor = sensorSet(sensor,'analogOffset',0);
sensor = sensorSet(sensor,'offsetFPNimage',[]);
sensor = sensorSet(sensor,'gainFPNimage',[]);
sensor = sensorSet(sensor,'gainFPNimage',[]);
sensor = sensorSet(sensor,'quantization','analog');

sensorName = ieParamFormat(sensorName);
switch sensorName
    case {'default','color','bayer','bayer(grbg)','bayer-grbg','bayergrbg'}
        filterOrder = [2,1;3,2];
        filterFile = 'rgb';
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'bayer(rggb)','bayer-rggb'}
        filterOrder = [1 2 ; 2 3];
        filterFile = 'rgb';
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'bayer(bggr)','bayer-bggr'}
        filterOrder = [3 2 ; 2 1];
        filterFile = 'rgb';
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'bayer(gbrg)','bayer-gbrg'}
        filterOrder = [2 3 ; 1 2];
        filterFile = 'rgb';
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'bayer(ycmy)','bayer-ycmy'}
        filterFile = 'cym';
        filterOrder = [2,1; 3,2];
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'bayer(cyym)','bayer-cyym'}
        filterFile = 'cym';
        filterOrder = [1 2 ; 2 3];
        sensor = sensorBayer(sensor,filterOrder,filterFile);
    case {'ideal'}
        % sensorType = 'human'  % 'rgb','monochrome'
        % cPattern = 'bayer'    % any sensorCreate option
        % sensorCreate('ideal',[],'human','bayer');
        pSize = 2e-6; sensorType = 'human'; cPattern = 'bayer';
        if length(varargin) >= 1, pSize = varargin{1}; end
        if length(varargin) >= 2, sensorType = varargin{2}; end
        if length(varargin) >= 3, cPattern = varargin{3}; end
        sensor = sensorCreateIdeal(sensorType,pSize,cPattern);

    case {'custom'}  % Often used for multiple channel
        % sensorCreate('custom',pixel,filterOrder,filterFile);
        if length(varargin) >= 1, filterOrder = varargin{1};
        else  % Must read it here
        end
        if length(varargin) >= 2, filterFile = varargin{2};
        else % Should read it here, NYI
            error('No filter file specified')
        end
        sensor = sensorCustom(sensor,filterOrder,filterFile);
    case {'fourcolor'}  % Often used for multiple channel
        % sensorCreate('custom',pixel,filterOrder,filterFile);
        if length(varargin) >= 1, filterOrder = varargin{1};
        else  % Must read it here
        end
        if length(varargin) >= 2, filterFile = varargin{2};
        else % Should read it here, NYI
            error('No filter file specified')
        end
        sensor = sensorCustom(sensor,filterOrder,filterFile);

    case 'monochrome'
        filterFile = 'Monochrome';
        sensor = sensorMonochrome(sensor,filterFile);
    case 'interleaved'
        % Create an interleaved sensor with one transparent and 3 color
        % filters.
        filterFile = 'interleavedRGBW.mat';
        filterOrder = [1 2; 3 4];
        sensor = sensorInterleaved(sensor,filterOrder,filterFile);
    case 'human'
        % See example in header
        % sensor = sensorCreate('human',pixel,params);
        if length(varargin) >= 1, params = varargin{1};
        else params = [];
        end

        % Assign key fields
        if checkfields(params,'sz'), sz = params.sz;
        else sz = []; end
        if checkfields(params,'rgbDensities'), rgbDensities = params.rgbDensities;
        else rgbDensities = []; end
        if checkfields(params,'coneAperture'), coneAperture = params.coneAperture;
        else coneAperture = []; end
        if checkfields(params,'rSeed'), rSeed = params.rSeed;
        else rSeed = [];
        end

        % Build up a human cone mosaic.
        [sensor, xy, coneType, rSeed, rgbDensities] = ...
            sensorCreateConeMosaic(sensor, sz, rgbDensities, coneAperture, rSeed, 'human');
        %  figure(1); conePlot(xy,coneType);
        
        % We don't want the pixel to saturate
        pixel = sensorGet(sensor,'pixel');
        pixel = pixelSet(pixel,'voltage swing',1);  % 1 volt
        sensor = sensorSet(sensor,'pixel',pixel);
        sensor = sensorSet(sensor,'exposure time',1); % 1 sec
        
        % Parameters are stored in case you want the exact same mosaic
        % again. Should we have sets and gets for this?
        sensor = sensorSet(sensor,'cone locs',xy);
        sensor = sensorSet(sensor,'cone type',coneType);
        sensor = sensorSet(sensor,'densities',rgbDensities);
        sensor = sensorSet(sensor,'rSeed',rSeed);

    case 'mouse'
        error('NYI: Needs to be fixed up with sensorCreateConeMosaic');
        filterFile = 'mouseColorFilters.mat';
        sensor = sensorMouse(sensor, filterFile);
        sensor = sensorSet(sensor, 'pixel', pixelCreate('mouse'));
    otherwise
        error('Unknown sensor type');
end

% Set the exposure time - this needs a CFA to be established to account for
% CFA exposure mode.
sensor = sensorSet(sensor,'integrationTime',0);
sensor = sensorSet(sensor,'autoexposure',1);    % Changed December 2009.
sensor = sensorSet(sensor,'CDS',0);

% Put in a default infrared filter.  All ones.
sensor = sensorSet(sensor,'irfilter',ones(sensorGet(sensor,'nwave'),1));
sensor = sensorSet(sensor,'mccRectHandles',[]);

return;

%-----------------------------
function sensor = sensorBayer(sensor,filterOrder,filterFile)
%
%   Create a default image sensor array structure.

sensor = sensorSet(sensor,'name',sprintf('bayer-%.0f',vcCountObjects('sensor')));
sensor = sensorSet(sensor,'filterorder',filterOrder);

% Read in a default set of filter spectra
[filterSpectra,filterNames] = sensorReadColorFilters(sensor,filterFile);
sensor = sensorSet(sensor,'filterspectra',filterSpectra);
sensor = sensorSet(sensor,'filternames',filterNames);

return;

%-----------------------------

%----------------------
function sensor = sensorMouse(sensor, filterFile)
%
% This isn't right.  The content below should be moved into
% sensorCreateConeMosaic and edited to be made right there.

error('Not yet implemented');
%
%    sensor = sensorSet(sensor,'name',sprintf('mouse-%.0f',vcCountObjects('sensor')));
%    sensor = sensorSet(sensor,'cfaPattern','mousePattern');
%
%    % try to get the current wavelengths from the scene or the oi.
%    % the mouse sees at different wavelengths than the human : we use
%    % 325-635 usually.
%    scene = vcGetObject('scene');
%    if isempty(scene)
%        getOi = 1;
%    else
%        spect = scene.spectrum.wave;
%        if isempty(spect),  getOi = 1;
%        else
%            mouseWave = spect;
%            getOi = 0;
%        end
%    end
%    if getOi
%       oi = vcGetObject('oi');
%       if isempty(oi), mouseWave = 325:5:635;
%       else spect = oi.optics.spectrum.wave;
%          if isempty(spect),  mouseWave = 325:5:635;
%          else                mouseWave = spect;
%          end
%       end
%    end
%    sensor = sensorSet(sensor,'wave',mouseWave);
%
%    [filterSpectra,filterNames] = sensorReadColorFilters(sensor,filterFile);
%    sensor = sensorSet(sensor,'filterSpectra',filterSpectra);
%    sensor = sensorSet(sensor,'filterNames',filterNames);

return;

%-----------------------------
function sensor = sensorInterleaved(sensor,filterOrder,filterFile)
%
%   Create a default interleaved image sensor array structure.

sensor = sensorSet(sensor,'name',sprintf('interleaved-%.0f',vcCountObjects('sensor')));
sensor = sensorSet(sensor,'cfaPattern',filterOrder);

% Read in a default set of filter spectra
[filterSpectra,filterNames] = sensorReadColorFilters(sensor,filterFile);
sensor = sensorSet(sensor,'filterSpectra',filterSpectra);
sensor = sensorSet(sensor,'filterNames',filterNames);

return;

%-----------------------------
function sensor = sensorCustom(sensor,filterOrder,filterFile)
%
%  Set up a sensor with multiple color filters.
%

sensor = sensorSet(sensor,'name',sprintf('custom-%.0f',vcCountObjects('sensor')));

sensor = sensorSet(sensor,'cfaPattern',filterOrder);

[filterSpectra,filterNames] = sensorReadColorFilters(sensor,filterFile);

% Force the first character of the filter names to be lower case
% This may not be necessary.  But we had a bug once and it is safer to
% force this. - BW
for ii=1:length(filterNames)
    filterNames{ii}(1) = lower(filterNames{ii}(1));
end

sensor = sensorSet(sensor,'filterSpectra',filterSpectra);
sensor = sensorSet(sensor,'filterNames',filterNames);

return;

%-----------------------------
function sensor = sensorMonochrome(sensor,filterFile)
%
%   Create a default monochrome image sensor array structure.
%

sensor = sensorSet(sensor,'name',sprintf('monochrome-%.0f', vcCountObjects('sensor')));

[filterSpectra,filterNames] = sensorReadColorFilters(sensor,filterFile);
sensor = sensorSet(sensor,'filterSpectra',filterSpectra);
sensor = sensorSet(sensor,'filterNames',filterNames);

sensor = sensorSet(sensor,'cfaPattern',1);      % 'bayer','monochromatic','triangle'

return;


