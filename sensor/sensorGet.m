function val = sensorGet(sensor,param,varargin)
%Get data from ISET image sensor array
%
%     val = sensorGet(sensor,param,varargin)
%
%  The (very long) sensor parameter list is described below.  The image
%  sensory array is often referred to as sensor, or sensor in the code.  The
%  sensor array includes a pixel data structure, and this structure has its
%  own accessor functions.  The pixel optics depend on microlens
%  structures, and there is a separate microlens analysis toolkit.
%
% A '*' indicates a routine that can return different spatial units.
%
% Examples:
%    val = sensorGet(sensor,'name')
%    val = sensorGet(sensor,'size');          % row,col
%    val = sensorGet(sensor,'dimension','um');
%    val = sensorGet(sensor,'Electrons',2);   % Second color type
%    val = sensorGet(sensor,'fov')            % degrees
%    val = sensorGet(sensor,'PIXEL')
%    val = sensorGet(sensor,'exposureMethod');% Single, bracketed, cfa
%    val = sensorGet(sensor,'nExposures')     % Number of exposures
%    val = sensorGet(sensor,'filtercolornames')
%    val = sensorGet(sensor,'exposurePlane'); % For bracketing simulation
%
% Basic sensor array parameters
%      {'name'}                 - this sensor name
%      {'type'}                 - always 'sensor'
%      {'row'}                  - sensor rows
%      {'col'}                  - sensor columns
%      {'size'}                 - (rows,cols)
%      {'height'}*              - sensor height (units)
%      {'width'}*               - sensor width  (units)
%      {'dimension'}*           - (height,width)
%      {'spatialsupport'}*      - position of pixels.
%      {'wspatialresolution'}*  - spatial distance between pixels (width)
%      {'hspatialresolution'}*  - spatial distance between pixels (height)
%
%  Field of view and sampling density
%      {'hfov'}   - horizontal field of view (deg)
%      {'vfov'}   - vertical field of view (deg)
%      {'hdegperpixel'} - horizontal deg per pixel
%      {'vdegperpixel'} - vertical deg per pixel
%      {'hdegperdistance'} - deg per unit horizontal distance *
%      {'vdegperdistance'} - deg per unit vertical distance *
%
% * Units are meters by default but can be set to 'um','mm', etc.
%
%  Sensor optics related
%      {'fov'}                  - sensor horizontal field of view
%      {'chiefRayAngle'}        - chief ray angle in radians at each pixel
%          sensorGet(sensor,'chiefRayAngle',sourceFocaLengthMeters)
%      {'chiefRayAngleDegrees'} - chief ray angle in degrees at each pixel
%          sensorGet(sensor,'chiefRayAngleDegrees',sourceFocaLengthMeters)
%      {'sensorEtendue'}        - optical efficiency at each pixel
%      {'microLens'}            - microlens data structure, accessed using
%          mlensGet() and mlensSet (optics toolbox only)
%
% Sensor array electrical processing properties and outputs
%      {'volts'}          - Sensor output in volts
%      {'response Ratio'}  - Peak data voltage divided by largest pixel voltage
%      {'digital Values'}  - Sensor output in digital units
%      {'electrons'}      - Sensor output in electrons
%         A color plane can be returned: sensorGet(sensor,'electrons',2);
%      {'dvorvolts'}      - Return either dv if present, otherwise volts
%      {'roi locs'}            - Stored region of interest (roiLocs)
%      {'roi rect'}
%      {'roi Volts'}       - Volts inside of stored region of interest
%         If there is no stored region of interest, ask the user to select.
%      {'roi Electrons'}   - Electrons inside of stored ROI, or user selects
%      {'analog Gain'}     - A scale factor that divides the sensor voltage
%                           prior to clipping
%      {'analogOffset'}   - Added to the voltage to stay away from zero, sometimes used
%                           to minimize the effects of dark noise at the low levels
%         Formula for offset and gain: (v + analogOffset)/analogGain)
%
%      {'sensorDynamicRange'}
%
%      {'quantization}   -  Quantization structre
%        {'nbits'}                - number of bits in quantization method
%        {'maxoutput'}            -
%        {'quantizationlut'}
%        {'quantizationmethod'}
%
% Sensor color filter array and related color properties
%     {'spectrum'}    - structure about spectral information
%       {'wave'}      - wavelength samples
%       {'binwidth'}  - difference between wavelength samples
%       {'nwave'}     - number of wavelength samples
%     {'color'}
%       {'filtertransmissivities'} - Filter transmissivity as a function of wave
%       {'infraredfilter'} - Normally the IR, but we sometimes put other
%        filters, such as macular pigment, in the ir slot.
%
%      {'cfaName'}     - Best guess at conventional CFA architecture name
%      {'filter Names'} - Cell array of filter names. The first letter of
%        each filter should indicate the filter color see sensorColorOrder
%        comments for more information
%      {'nfilters'}    - number of color filters
%      {'filter Color Letters'} - A string with each letter being the first
%        letter of a color filter; the letters are from the list in
%        sensorColorOrder. The pattern field(see below) describes their
%        position in array.
%      {'filter Color Letters Cell'} -  As above, but returned in a cell array
%         rather than a string
%      {'filter plotcolors'} - one of rgbcmyk for plotting for this filter
%      {'spectral QE'} - Product of photodetector QE, IR and color filters
%           Does not include vignetting or pixel fill factor.
%      {'pattern'}     - Matrix that defines the color filter array
%        pattern; e.g. [1 2; 2 3] if the spectrra are RGB and the pattern
%        is a conventional Bayer [r g; g b]
%
% Noise properties
%      {'dsnusigma'}           - Dark signal nonuniformity (DSNU) parameter (volts)
%      {'prnusigma'}           - Photoresponse nonuniformity (PRNU) parameter (std dev percent)
%      {'fpnparameters'}       - (dsnusigma,prnusigma)
%      {'dsnuimage'}           - Dark signal non uniformity (DSNU) image
%      {'prnuimage',}          - Photo response non uniformity (PRNU) image
%      {'columnfpn'}           - Column (offset,gain) parameters
%      {'columndsnu'}          - The column offset parameters (Volts)
%      {'columnprnu'}          - The column gain parameters (std dev in Volts)
%      {'coloffsetfpnvector'}  - The sensor column offset data
%      {'colgainfpnvector'}    - The sensor column gain data
%      {'noiseFlag'}           - Governs sensorCompute noise calculations 
%                                 0 no noise at all
%                                 1 shot noise, no electronics noise
%                                 2 shot noise and electronics noise
%      {'reuse noise'}         - Use the stored noise seed
%      {'noise seed'}          - Stored noise seed from last run
%
%  The pixel structure
%      {'pixel'}  - pixel structure is complex; accessed using pixelGet();
%
%  Sensor computation parameters
%      {'autoExposure'}   - Auto-exposure flag (0,1)
%      {'exposureTime'}   - Exposure time (sec)
%      {uniqueExptimes'}  - Unique values from the exposure time list
%      {'exposurePlane'}  - Select exposure for display when bracketing
%      {'cds'}            - Correlated double-sampling flag
%      {'pixelvignetting'}- Include pixel optical efficiency in
%             sensorCompute.
%             val = 1 Means vignetting only.
%             val = 2 means microlens included. (Microlens shifting NYI).
%             otherwise, skip both vignetting and microlens.
%      {'sensorCompute','sensorComputeMethod'}
%         % Swap in a sensorCompute routine.  If this is empty, then the
%         % standard vcamera\sensor\mySensorCompute routine will be used.
%      {'ngridsamples','pixelsamples','nsamplesperpixel','npixelsamplesforcomputing'}
%         % Default is 1.  If not parameter is not set, we return the default.
%      {'consistency','computationalconsistency'}
%         % If the consistency field is not present, assume false and set it
%         % false.  This checks whether the parameters and the displayed
%         % image are consistent/updated.
%
% Human sensor special case
%    {'human'} - The structure with all human parameters.  Applies only
%      when the name contains the string 'human' in it
%      {'cone type'} - K=1, L=2, M=3 or S=4 (K means none)
%      {'densities'} - densities used to generate mosaic (K,L,M,S)
%      {'rSeed'}     - seed for generating mosaic
%      {'xy'}        - xy position of the cones in the mosaic
%
% Sensor motion
%       {'sensor movement'}     - A structure of sensor motion information
%       {'movement positions'}  - Nx2 vector of (x,y) positions in deg
%       {'frames per position'} - N vector of exposures per position
%       {'sensor positions x'}  - 1st column (x) of sensor positions (deg)
%       {'sensor positions y'}  - 2nd column (y) of sensor positions (deg)
%
% Miscellaneous
%     {'mccRectHandles'}  - Handles for the rectangle selections in an MCC
%     {'mcccornerpoints'} - Corner points for the whole MCC chart
%
% Copyright ImagEval Consultants, LLC, 2005.

if ~exist('param','var') || isempty(param), error('Param must be defined.'); end

% Default return value.
val = [];

param = ieParamFormat(param);

switch param

    case {'name'}
        if checkfields(sensor,'name'), val = sensor.name; end
    case {'type'}
        if checkfields(sensor,'type'), val = sensor.type; end

    case {'rows','row'}
        % There should not be a rows/cols field at all, right, unless the
        % data field is empty?
        if checkfields(sensor,'data','volts')
            val = size(sensor.data.volts,1);
            return;
        elseif checkfields(sensor,'rows'), val = sensor.rows;
        end
    case {'cols','col'}
        % We keep rows/cols field at all, right, unless the
        % data field is empty?
        if checkfields(sensor,'data','volts')
            val = size(sensor.data.volts,2);
            return;
        elseif checkfields(sensor,'cols'), val = sensor.cols;
        end
    case {'size','arrayrowcol'}
        % Note:  dimension is (x,y) but size is (row,col)
        val = [sensorGet(sensor,'rows'),sensorGet(sensor,'cols')];

    case {'height','arrayheight'}
        val = sensorGet(sensor,'rows')*sensorGet(sensor,'deltay');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
    case {'width','arraywidth'}
        val = sensorGet(sensor,'cols')*sensorGet(sensor,'deltax');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'dimension'}
        val = [sensorGet(sensor,'height'), sensorGet(sensor,'width')];
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

        % The resolutions also represent the center-to-center spacing of the pixels.
    case {'wspatialresolution','wres','deltax','widthspatialresolution'}
        PIXEL = sensorGet(sensor,'pixel');
        val = pixelGet(PIXEL,'width') + pixelGet(PIXEL,'widthGap');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'hspatialresolution','hres','deltay','heightspatialresolultion'}
        PIXEL = sensorGet(sensor,'pixel');
        val = pixelGet(PIXEL,'height') + pixelGet(PIXEL,'heightGap');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'spatialsupport','xyvaluesinmeters'}
        % ss = sensorGet(sensor,'spatialSupport',units)
        nRows = sensorGet(sensor,'rows');
        nCols = sensorGet(sensor,'cols');
        pSize = pixelGet(sensorGet(sensor,'pixel'),'size');
        val.y = linspace(-nRows*pSize(1)/2 + pSize(1)/2, nRows*pSize(1)/2 - pSize(1)/2,nRows);
        val.x = linspace(-nCols*pSize(2)/2 + pSize(2)/2,nCols*pSize(2)/2 - pSize(2)/2,nCols);
        if ~isempty(varargin)
            val.y = val.y*ieUnitScaleFactor(varargin{1});
            val.x = val.x*ieUnitScaleFactor(varargin{1});
        end

    case {'chiefrayangle','cra','chiefrayangleradians','craradians','craradian','chiefrayangleradian'}
        % Return the chief ray angle for each pixel in radians
        % sensorGet(sensor,'chiefRayAngle',sourceFLMeters)
        support = sensorGet(sensor,'spatialSupport');   %Meters

        % Jst flipped .x and .y positions
        [X,Y] = meshgrid(support.x,support.y);
        if isempty(varargin),
            optics = oiGet(vcGetObject('OI'),'optics');
            sourceFL = opticsGet(optics,'focalLength'); % Meters.
        else
            sourceFL = varargin{1};
        end

        % Chief ray angle of every pixel in radians
        val = atan(sqrt(X.^2 + Y.^2)/sourceFL);

    case {'chiefrayangledegrees','cradegrees','cradegree','chiefrayangledegree'}
        % sensorGet(sensor,'chiefRayAngleDegrees',sourceFL)
        if isempty(varargin),
            optics = oiGet(vcGetObject('OI'),'optics');
            sourceFL = opticsGet(optics,'focalLength'); % Meters.
        else sourceFL = varargin{1};
        end
        val = ieRad2deg(sensorGet(sensor,'cra',sourceFL));
    case {'etendue','sensoretendue'}
        % The size of etendue etnrie matches the row/col size of the sensor
        % array. The etendue is computed using the chief ray angle at each
        % pixel and properties of the microlens structure. Routines exist
        % for calculating the optimal placement of the microlens
        % (mlRadiance). We store the bare etendue (no microlens) in the
        % vignetting location.  The improvement due to the microlens array
        % can be calculated by sensor.etendue/sensor.data.vignetting.  We need to
        % be careful about clearing these fields and data consistency.
        if checkfields(sensor,'etendue'), val = sensor.etendue; end


    case {'voltage','volts'}
        % sensorGet(sensor,'volts',i) gets the ith sensor data in a vector.
        % sensorGet(sensor,'volts') gets all the sensor data in a plane.
        % This syntax applies to most of the voltage/electron/dv gets
        % below.
        %
        if checkfields(sensor,'data','volts'), val = sensor.data.volts; end
        if ~isempty(varargin), val = sensorColorData(val,sensor,varargin{1}); end
    case{'volts2maxratio','responseratio'}
        v = sensorGet(sensor,'volts');
        pixel = sensorGet(sensor,'pixel');
        sm = pixelGet(pixel,'voltageswing');
        val = max(v(:))/sm;
    case {'analoggain','ag'}
        if checkfields(sensor,'analogGain'), val = sensor.analogGain;
        else val = 1;
        end
    case {'analogoffset','ao'}
        if checkfields(sensor,'analogGain'), val = sensor.analogOffset;
        else   val = 0;
        end
    case {'dv','digitalvalue','digitalvalues'}
        if checkfields(sensor,'data','dv'),val = sensor.data.dv; end
        % Pull out a particular color plane
        if ~isempty(varargin) && ~isempty(val)
            val = sensorColorData(val,sensor,varargin{1});
        end

    case {'electron','electrons','photons'}
        % sensorGet(sensor,'electrons');
        % sensorGet(sensor,'electrons',2);
        % This is also used for human case, where we call the data photons,
        % as in photon absorptions.
        pixel = sensorGet(sensor,'pixel');
        val = sensorGet(sensor,'volts')/pixelGet(pixel,'conversionGain');

        % Pull out a particular color plane
        if ~isempty(varargin), val = sensorColorData(val,sensor,varargin{1}); end
        % Electrons are ints
        val = round(val);

    case {'dvorvolts'}
        val = sensorGet(sensor,'dv');
        if isempty(val), val = sensorGet(sensor,'volts'); end

        % Region of interest for data handling
    case {'roi','roilocs'}
        % roiLocs = sensorGet(sensor,'roi');
        % This is the default, which is to return the roi as roi locations,
        % an Nx2 matrix or (r,c) values.
        if checkfields(sensor,'roi')
            % The data can be stored as a rect or as roiLocs.
            val = sensor.roi;
            if size(val,2) == 4, val = vcRect2Locs(val); end
        end
    case {'roirect'}
        % sensorGet(sensor,'roi rect')
        % Return ROI as a rect
        if checkfields(sensor,'roi')
            % The data can be stored as a rect or as roiLocs.
            val = sensor.roi;
            if size(val,2) ~= 4, val =  vcLocs2Rect(val); end
        end
    case {'roivolts','roidata','roidatav','roidatavolts'}
        if checkfields(sensor,'roi')
            roiLocs = sensorGet(sensor,'roi locs');
            val = vcGetROIData(sensor,roiLocs,'volts');
        else warning('No sensor.roi field.  Returning empty voltage data.');
        end
    case {'roielectrons','roidatae','roidataelectrons'}
        if checkfields(sensor,'roi')
            roiLocs = sensorGet(sensor,'roi locs');
            val = vcGetROIData(sensor,roiLocs,'electrons');
        else warning('No sensor.roi field.  Returning empty electron data.');
        end
        
        % Quantization structure
    case {'quantization','quantizationstructure'}
        val = sensor.quantization;
    case {'nbits','bits'}
        if checkfields(sensor,'quantization','bits'), val = sensor.quantization.bits; end
    case {'max','maxoutput'}
        nbits = sensorGet(sensor,'nbits');
        if isempty(nbits),
            pixel = sensorGet(sensor,'pixel');
            val = pixelGet(pixel,'voltageswing');
        else val = 2^nbits;
        end
    case {'lut','quantizationlut'}
        if checkfields(sensor,'quantization','lut'), val = sensor.quantization.lut; end
    case {'qMethod','quantizationmethod'}
        if checkfields(sensor,'quantization','method'), val = sensor.quantization.method; end

        % Color structure
    case 'color'
        val = sensor.color;
    case {'filterspectra','colorfilters'}
        val = sensor.color.filterSpectra;
    case {'filternames'}
        val = sensor.color.filterNames;
    case {'filtercolorletters'}
        % The color letters returned here are in the order of the filter
        % column position in the matrix of filterSpectra. Only the first
        % letter of the filter name is returned.  This information is used
        % in combination with sensorColorOrder to determine plot colors.
        % The letters are a string.
        %
        % The pattern field(see below) describes the position for each
        % filter in the block pattern of color filters.
        names = sensorGet(sensor,'filternames');
        for ii=1:length(names), val(ii) = names{ii}(1); end
        val = char(val);
    case {'filtercolorletterscell'}
        cNames = sensorGet(sensor,'filterColorLetters');
        nFilters = length(cNames);
        val = cell(nFilters,1);
        for ii=1:length(cNames), val{ii} = cNames(ii); end

    case {'filternamescellarray','filtercolornamescellarray','filternamescell'}
        % N.B.  The order of filter colors returned here corresponds to
        % their position in the columns of filterspectra.  The values in
        % pattern (see below) describes their position in array.
        names = sensorGet(sensor,'filternames');
        for ii=1:length(names), val{ii} = char(names{ii}(1)); end
    case {'filterplotcolor','filterplotcolors'}
        % Return an allowable plotting color for this filter, based on the
        % first letter of the filter name.
        % letter = sensorGet(sensor,'filterPlotColor');
        letters = sensorGet(sensor,'filterColorLetters');
        if isempty(varargin), val = letters;
        else                  val = letters(varargin{1});
        end
        % Only return an allowable color.  We could allow w (white) but we
        % don't for now.
        for ii=1:length(val)
            if ~ismember(val(ii),'rgbcmyk'), val(ii) = 'k'; end
        end
    case {'ncolors','nfilters','nsensors','nsensor'}
        val = size(sensorGet(sensor,'filterSpectra'),2);
    case {'ir','infraredfilter','irfilter','otherfilter'}
        % We sometimes put other filters, such as macular pigment, in this
        % slot.  Perhaps we should have an other filter slot.
        if checkfields(sensor,'color','irFilter'), val = sensor.color.irFilter; end
    case {'spectralqe','sensorqe','sensorspectralqe'}
        val = sensorSpectralQE(sensor);

        % There should only be a spectrum associated with the
        % sensor, not with the pixel.  I am not sure how to change over
        % to a single spectral representation, though.  If pixels never
        % existed without an sensor, ... well I am not sure how to get the sensor
        % if only the pixel is passed in.  I am not sure how to enforce
        % consistency. -- BW
    case {'spectrum','sensorspectrum'}
        val = sensor.spectrum;
    case {'wave','wavelength'}
        val = sensor.spectrum.wave(:);
    case {'binwidth','waveresolution','wavelengthresolution'}
        wave = sensorGet(sensor,'wave');
        if length(wave) > 1, val = wave(2) - wave(1);
        else val = 1;
        end
    case {'nwave','nwaves','numberofwavelengthsamples'}
        val = length(sensorGet(sensor,'wave'));

        % Color filter array quantities
    case {'cfa','colorfilterarray'}
        val = sensor.cfa;

        % I removed the unitBlock data structure because everything that
        % was in unit block can be derived from the cfa.pattern entry.  We
        % are coding the cfa.pattern entry as a small matrix.  So, for
        % example, if it is a 2x2 Bayer pattern, cfa.pattern = [1 2; 2 3]
        % for a red, green, green, blue pattern.  The former entries in
        % unitBlock are redundant with this value and the pixel size.  So,
        % we got rid of them.
    case {'unitblockrows'}
        % sensorGet(sensor,'unit block rows')
        
        % Human patterns don't have block sizes.
        if sensorCheckHuman(sensor), val=1;
        else val = size(sensorGet(sensor,'pattern'),1);
        end
        
    case 'unitblockcols'
        % sensorGet(sensor,'unit block cols')
        
        % Human patterns don't have block sizes.
        if sensorCheckHuman(sensor), val=1;
        else val = size(sensorGet(sensor,'pattern'),2);
        end
        
    case {'cfasize','unitblocksize'}
        % We use this to make sure the sensor size is an even multiple of
        % the cfa size. This could be a pair of calls to cols and rows
        % (above).
        
        % Human patterns don't have block sizes.
        if sensorCheckHuman(sensor), val= [1 1];
        else    val = size(sensorGet(sensor,'pattern'));
        end
        
    case 'unitblockconfig'
        % val = sensor.cfa.unitBlock.config;
        % Is this still used?
        pixel = sensorGet(sensor,'pixel');
        p = pixelGet(pixel,'pixelSize','m');
        [X,Y] = meshgrid((0:(size(cfa.pattern,2)-1))*p(2),(0:(size(cfa.pattern,1)-1))*p(1));
        val = [X(:),Y(:)];
    
    case {'patterncolors','pcolors','blockcolors'}
        % patternColors = sensorGet(sensor,'patternColors');
        % Returns letters suggesting the color of each pixel
        
        pattern = sensorGet(sensor,'pattern');  %CFA block
        filterColorLetters = sensorGet(sensor,'filterColorLetters');
        knownColorLetters = sensorColorOrder('string');
        knownFilters = ismember(filterColorLetters,knownColorLetters);
        % Assign unknown color filter strings to black (k).
        l = find(~knownFilters, 1);
        if ~isempty(l), filterColorLetters(l) = 'k'; end
        % Create a block that has letters instead of numbers
        val = filterColorLetters(pattern);

    case {'pattern','cfapattern'}
        if checkfields(sensor,'cfa','pattern'), val = sensor.cfa.pattern; end
    case 'cfaname'
        % We look up various standard names
        val = sensorCFAName(sensor);

        % Pixel related parameters
    case 'pixel'
        val = sensor.pixel;
        
    case {'dr','dynamicrange','sensordynamicrange'}
        val = sensorDR(sensor);

    case 'diffusionmtf'
        val = sensor.diffusionMTF;

        % These are pixel-wise FPN parameters
    case {'fpnparameters','fpn','fpnoffsetgain','fpnoffsetandgain'}
        val = [sensorGet(sensor,'sigmaOffsetFPN'),sensorGet(sensor,'sigmaGainFPN')];
    case {'dsnulevel','sigmaoffsetfpn','offsetfpn','offset','offsetsd','dsnusigma','sigmadsnu'}
        % This value is stored in volts
        val = sensor.sigmaOffsetFPN;
    case {'sigmagainfpn','gainfpn','gain','gainsd','prnusigma','sigmaprnu','prnulevel'}
        % This is a percentage, between 0 and 100, always.
        val = sensor.sigmaGainFPN;
    
    case {'dsnuimage','offsetfpnimage'} % Dark signal non uniformity (DSNU) image
        % These should probably go away because we compute them afresh
        % every time.
        if checkfields(sensor,'offsetFPNimage'), val = sensor.offsetFPNimage; end
    case {'prnuimage','gainfpnimage'}  % Photo response non uniformity (PRNU) image
        % These should probably go away because we compute them afresh
        % every time.
        if checkfields(sensor,'gainFPNimage'), val = sensor.gainFPNimage; end

        % These are column-wise FPN parameters
    case {'columnfpn','columnfixedpatternnoise','colfpn'}
        % This is stored as a vector (offset,gain) standard deviations in
        % volts.  This is unlike the storage format for array dsnu and prnu.
        if checkfields(sensor,'columnFPN'), val = sensor.columnFPN; 
        else
            val = [0,0];
        end
    case {'columndsnu','columnfpnoffset','colfpnoffset','coldsnu'}
        tmp = sensorGet(sensor,'columnfpn'); val = tmp(1);
    case {'columnprnu','columnfpngain','colfpngain','colprnu'}
        tmp = sensorGet(sensor,'columnfpn'); val = tmp(2);
    case {'coloffsetfpnvector','coloffsetfpn','coloffset'}
        if checkfields(sensor,'colOffset'), val = sensor.colOffset; end
    case {'colgainfpnvector','colgainfpn','colgain'}
        if checkfields(sensor,'colGain'),val = sensor.colGain; end
        
        % Noise management
    case {'noiseflag','shotnoiseflag'}
        % 0 means no noise
        % 1 means shot noise but no electronics noise
        % 2 means shot noise and electronics noise
        if checkfields(sensor,'noiseFlag'), val = sensor.noiseFlag;
        else val = 2;    % Compute both electronic and shot noise
        end
    case {'reusenoise'}
        if checkfields(sensor,'reuseNoise'), val = sensor.reuseNoise;
        else val = 0;    % Do not reuse
        end
    case {'noiseseed'}
        if checkfields(sensor,'noiseSeed'), val = sensor.noiseSeed;
        else randn('seed');    % Compute both electronic and shot noise
        end

    case {'ngridsamples','pixelsamples','nsamplesperpixel','npixelsamplesforcomputing'}
        % Default is 1.  If not parameter is not set, we return the default.
        if checkfields(sensor,'samplesPerPixel'),val = sensor.samplesPerPixel;
        else val = 1;
        end

        % Exposure related
    case {'exposuremethod','expmethod'}
        % We plan to re-write the exposure parameters into a sub-structure
        % that lives inside the sensor, sensor.exposure.XXX
        tmp = sensorGet(sensor,'exptimes');
        p   = sensorGet(sensor,'pattern');
        if     isscalar(tmp), val = 'singleExposure';
        elseif isvector(tmp),  val = 'bracketedExposure';
        elseif isequal(size(p),size(tmp)),  val = 'cfaExposure';
        end
    case {'integrationtime','integrationtimes','exptime','exptimes','exposuretimes','exposuretime','exposureduration','exposuredurations'}
        % This can be a single number, a vector, or a matrix that matches
        % the size of the pattern slot. Each one of these cases is handled
        % differently by sensorComputeImage.  The units are seconds by
        % default.
        % sensorGet(sensor,'expTime','s')
        % sensorGet(sensor,'expTime','us')
        val = sensor.integrationTime;
        if ~isempty(varargin)
            val = val*ieUnitScaleFactor(varargin{1});
        end
    case {'uniqueintegrationtimes','uniqueexptime','uniqueexptimes'}
        val = unique(sensor.integrationTime);
    case {'centralexposure','geometricmeanexposuretime'}
        % We return the geometric mean of the exposure times
        % We should consider making this the geometric mean of the unique
        % exposures.
        eTimes = sensorGet(sensor,'exptimes');
        val = prod(eTimes(:))^(1/length(eTimes(:)));
    case {'autoexp','autoexposure','automaticexposure'}
        val = sensor.AE;
    case {'nexposures'}
        % We can handle multiple exposure times.
        val = numel(sensorGet(sensor,'expTime'));
    case {'exposureplane'}
        % When there are multiple exposures, show the middle integration
        % time, much like a bracketing idea.
        % N.B. In the case where there is a different exposure for every
        % position in the CFA, we wouldn't normally use this.  In that case
        % we only have a single integrated CFA.
        if checkfields(sensor,'exposurePlane'), val = sensor.exposurePlane;
        else val = floor(sensorGet(sensor,'nExposures')/2) + 1;
        end

    case {'cds','correlateddoublesampling'}
        val = sensor.CDS;

        % Microlens related
    case {'vignettingflag','vignetting','pixelvignetting','bareetendue','sensorbareetendue','nomicrolensetendue'}
        % If the vignetting flag has not been set, treat it as 'skip',
        % which is 0.
        if checkfields(sensor,'data','vignetting'),
            if isempty(sensor.data.vignetting), val = 0;
            else                             val = sensor.data.vignetting;
            end
        else
            val = 0;
        end
    case {'vignettingname'}
        pvFlag = sensorGet(sensor,'vignettingFlag');
        switch pvFlag
            case 0
                val = 'skip';
            case 1
                val = 'bare';
            case 2
                val = 'centered';
            case 3
                val = 'optimal';
            otherwise
                error('Bad pixel vignetting flag')
        end

    case {'microlens','ulens','mlens','ml'}
        if checkfields(sensor,'ml'), val = sensor.ml; end

        % Field of view and sampling density
    case {'fov','sensorfov','fovhorizontal','fovh','hfov'}
        % sensorGet(sensor,'fov',scene,oi); - Explicit is preferred
        % sensorGet(sensor,'fov');          - Uses defaults
        %
        % This is the horizontal field of view (default)
        % We compute it from the distance between the lens and the sensor
        % surface and we also use the sensor array width.
        % The assumption here is that the sensor is at the proper focal
        % distance for the scene.  If the scene is at infinity, then the
        % focal distance is the focal length.  But if the scene is close,
        % then we 
        %
        if ~isempty(varargin), scene = varargin{1};
        else                   scene = vcGetObject('scene');
        end
        if length(varargin) > 1, oi = varargin{2};
        else                     oi = vcGetObject('oi');
        end
        % If no scene is sent in, assume the scene is infinitely far away.
        if isempty(scene), sDist = Inf;
        else               sDist = sceneGet(scene,'distance');
        end
        % If there is no oi, then use the default optics focal length. The
        % image distance depends on the scene distance and focal length via
        % the lensmaker's formula, (we assume the sensor is at the proper
        % focal distance).
        if isempty(oi), distance = opticsGet(opticsCreate,'focalLength');
        else            distance = opticsGet(oiGet(oi,'optics'),'imageDistance',sDist);
        end
        width = sensorGet(sensor,'arraywidth');
        val = ieRad2deg(2*atan(0.5*width/distance));
    case {'fovvertical','vfov','fovv'}
        % This is  the vertical field of view
        oi = vcGetObject('OI');
        if isempty(oi), oi = oiCreate; end
        distance = opticsGet(oiGet(oi,'optics'),'imageDistance');
        height = sensorGet(sensor,'arrayheight');
        val = ieRad2deg(2*atan(0.5*height/distance));
    case {'hdegperpixel','degpersample','degreesperpixel'}
        % Horizontal field of view divided by number of pixels
        sz =  sensorGet(sensor,'size');
        val = sensorGet(sensor,'hfov')/sz(2);
    case {'vdegperpixel','vdegreesperpixel'}
        sz =  sensorGet(sensor,'size');
        val = sensorGet(sensor,'vfov')/sz(1);
    case {'hdegperdistance','degperdistance'}
        % sensorGet(sensor,'h deg per distance','mm')
        % Degrees of visual angle per meter or other spatial unit
        if isempty(varargin), unit = 'm'; else unit = varargin{1}; end
        width = sensorGet(sensor,'width',unit);
        fov =  sensorGet(sensor,'fov');
        val = fov/width; 
    case {'vdegperdistance'}
        % sensorGet(sensor,'v deg per distance','mm') Degrees of visual
        % angle per meter or other spatial unit
        if isempty(varargin), unit = 'm'; else unit = varargin{1}; end
        width = sensorGet(sensor,'height',unit);
        fov =  sensorGet(sensor,'vfov');
        val = fov/width;
        
        % Computational flags
    case {'sensorcompute','sensorcomputemethod'}
        % Swap in a sensorCompute routine.  If this is empty, then the
        % standard vcamera\sensor\mySensorCompute routine will be used.
        if checkfields(sensor,'sensorComputeMethod'), val = sensor.sensorComputeMethod;
        else  val = 'mySensorCompute';  end
    case {'consistency','computationalconsistency'}
        % If the consistency field is not present, assume false and set it
        % false.  This checks whether the parameters and the displayed
        % image are consistent/updated.
        if checkfields(sensor,'consistency'), val = sensor.consistency;
        else sensorSet(sensor,'consistency',0); val = 0;
        end

    case {'mccrecthandles'}
        % These are handles to the squares on the MCC selection regions
        % see ieMacbethSelect
        if checkfields(sensor,'mccRectHandles'), val = sensor.mccRectHandles; end
    case {'mccpointlocs','mcccornerpoints'}
        % Corner points for the whole MCC chart
        if checkfields(sensor,'mccCornerPoints'), val = sensor.mccCornerPoints; end

        % Human cone case
    case {'human'}
        % Structure containing information about human cone case
        % Only applies when the name field has the string 'human' in it.
        if checkfields(sensor,'human'), val = sensor.human; end
    case {'humancone type','conetype'}
        % Blank (K) K=1 and L,M,S cone at each position
        % L=2, M=3 or S=4 (K means none)
        % Some number of cone types as cone positions.
        if checkfields(sensor,'human','coneType'), val = sensor.human.coneType; end
    case {'humanconedensities','densities'}
        %- densities used to generate mosaic (K,L,M,S)
        if checkfields(sensor,'human','densities'), val = sensor.human.densities; end
    case   {'humanconelocs','conexy','conelocs','xy'}
        %- xy position of the cones in the mosaic
        if checkfields(sensor,'human','xy'), val = sensor.human.xy; end
    case {'humanrseed','humanconeseed'}
        % random seed for generating cone mosaic
        % Should get rid of humanrseed alias
        if checkfields(sensor,'human','rSeed'), val = sensor.human.rSeed; end

        % Sensor motion -  used for eye movements or camera shake
    case {'sensormovement','eyemovement'}
        % A structure with sensor motion information
        if checkfields(sensor,'movement')
            val = sensor.movement; 
        end
    case {'movementpositions','sensorpositions'}
        % Nx2 vector of (x,y) positions in deg
        if checkfields(sensor,'movement','pos'), val = sensor.movement.pos;
        else val = [0,0]; 
        end
    case {'sensorpositionsx'}
        if checkfields(sensor,'movement','pos')
            val = sensor.movement.pos(:,1);
        else val = 0;
        end
    case {'sensorpositionsy'}
        if checkfields(sensor,'movement','pos')
            val = sensor.movement.pos(:,2);
        else val = 0;
        end
    case {'framesperposition','exposuretimesperposition','etimeperpos'}
        % Exposure frames for each (x,y) position
        % This is a vector with some number of exposures for each x,y
        % position (deg)
        if checkfields(sensor,'movement','framesPerPosition')
            val = sensor.movement.framesPerPosition;
        else
            val = 1;
        end
        
        %
    otherwise
        error('Unknown sensor parameter.');

end

return;

%--------------------------------
function cfaName = sensorCFAName(sensor)
% Determine the cfa name in order to populate the lists in pop up boxes.
%
%     cfaName = sensorCFAName(sensor)
%
% If sensor is passed in, return a standard name for the CFA types.
% If sensor is empty or absent return the list of standard names.
%
% The normal naming convention for CFA is to read left to right.  For
% example,
%     G B
%     R G
% is coded as 'gbrg'
% The pattern matrix stored in sensor is a 2x2 array, usually.  Thus, the
% values are stored as
%     [2 1; 3 2]
%   =    2 1
%        3 2
%
% This is a bit confusing.  Sorry.
%
% Examples:
%   cfaName = sensorCFAName(sensor)
%   cfaNames = sensorCFAName
%

if ieNotDefined('sensor')
    cfaName = sensorCFANameList;
    return;
end

p = sensorGet(sensor,'pattern');
filterColors = sensorGet(sensor,'filterColorLetters');
filterColors = sort(filterColors);

if length(p) == 1
    cfaName = 'Monochrome';
elseif length(p) > 4
    cfaName = 'Other'; return;
elseif isequal(p,[ 2 1; 3 2]) && strcmp(filterColors,'bgr');
    cfaName = 'bayer-grbg';
elseif isequal(p,[ 1 2; 2 3]) && strcmp(filterColors,'bgr');
    cfaName = 'bayer-rggb';
elseif isequal(p,[ 2 3; 1 2]) && strcmp(filterColors,'bgr');
    cfaName = 'bayer-gbrg';
elseif isequal(p,[ 3 2; 2 1]) && strcmp(filterColors,'bgr');
    cfaName = 'bayer-bggr';
elseif isequal(p,[ 2 3; 1 2]) && strcmp(filterColors,'cym');
    cfaName = 'bayer-ycmy';
elseif  isequal(p,[ 1 3; 2 4])
    cfaName = 'Four Color';
else
    cfaName = 'Other';
end

return;

%------------------------------------------
function spectralQE = sensorSpectralQE(sensor)
% Compute the sensor spectral QE
%
%    spectralQE = sensorSpectralQE(sensor)
%
% Combine the pixel detector, the sensor color filters, and the infrared
% filter into a sensor spectral QE.   If the variable wave is in the
% calling arguments, the spectralQE is returned interpolated to the
% wavelengths in wave.
%

sensorIR = sensorGet(sensor,'irfilter');
cf = sensorGet(sensor,'filterspectra');
% isaWave = sensorGet(sensor,'wave');

pixelQE = pixelGet(sensor.pixel,'qe');
if isempty(pixelQE)
    warndlg('Empty pixel QE. Assuming QE(lambda) = 1.0');
    pixelQE = ones(size(sensorIR(:)));
end

% Compute the combined wavelength sensitivity including the ir filter, the
% pixel QE, and the color filters.
spectralQE = diag(pixelQE(:) .* sensorIR(:)) * cf;

return

%------------------------
function val = sensorColorData(data,sensor,whichSensor)
% Retrieve data from one of the sensor planes.
%
% The data are returned in a vector, not a plane.
%
% This should also be able to return a planar image with zeros, not just a
% vector.  But surely this form was written some time ago.

% In most cases, we can convert the data to a 3D and return the values in
% the RGB 3D.  In human, we have the whole pattern.  Probably we should
% always get the
%
% This might work in both cases ... but sensorDetermineCFA may not be
% running right for the human case.  Have a look.  For now, we are only
% using the 'ideal' condition with human.
%
% electrons = sensorGet(sensor,'electrons');
% [tmp,n] = sensorDetermineCFA(sensor);
% b = (n==whichSensor);
% val = electrons(b);

% The one we have been using
rgb        = plane2mosaic(data,sensor);
thisSensor = rgb(:,:,whichSensor);
l   = ~isnan(thisSensor);
val = thisSensor(l);

return;

% TODO:
%
% The pixel height and width may differ from the center-to-center distance
% between pixels in the sensor.  This is because of additional gaps between
% the pixels (say for wires). The center-to-center spacing between pixels
% is contained in the deltaX, deltaY parameters.
%
% For consistency with the other structures, I also introduced the
% parameters hspatialresolution and wspatialresolution to refer to the
% deltaY and deltaX center-to-center spacing of the pixels.  We might
% consider adding just hresolution and wresolution for spatial, with
% angular being special.
%
% In several cases we use the spatial coordinates of the sensor array to
% define a coordinate system, say for the optical image.  In this case, the
% integer coordinates are defined by the deltaX and deltaY values.
%
% get cfa matrix as letters or numbers via sensorDetermineCFA in here.

