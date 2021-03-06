function val = oiGet(oi,parm,varargin)
%Get properties and derived quantities from an optical image structure
%
%     val = oiGet(oi,parm,varargin)
%
%  Optical image parameters are stored in a structure. Some parameters are
%  stored directly, others are calculated from  the data structure.  We
%  store the unique values and  calculate many derived values. 
%
%  The optical image structures are stored in a cell array, vcSESSION.OPTICALIMAGE{}
%
%  To retrieve the currently selected optical image, use either
%     [val, oi] = vcGetSelectedObject('OI');
%     oi = vcGetObject('OI');
%
%  A '*' indicates that the syntax sceneGet(scene,param,unit) can be used, where
%  unit specifies the spatial scale of the returned value:  'm', 'cm', 'mm',
%  'um', 'nm'.  Default is meters ('m').
%
% Examples:
%    oiGet(oi,'rows')
%    oiGet(oi,'wave')
%    oiGet(oi,'optics')
%    oiGet(oi,'area','mm')
%    oiGet(oi,'wres','microns')
%    oiGet(oi,'angularresolution')
%    oiGet(oi,'distPerSamp','mm')
%    oiGet(oi,'spatial support','microns');   % Meshgrid of zero-centered (x,y) values
%    oiGet(oi,'rgb image');
%
%  General properties
%      {'name'}           - optical image name
%      {'type'}           - 'opticalimage'
%      {'filename'}       - if read from a file, could store here
%      {'consistency'}    - the oiWindow display reflects the current state (1) or not (0).
%      {'rows'}           - number of row samples
%      {'cols'}           - number of col samples
%      {'size'}           - rows,cols
%      {'image distance'} - distance from lens to image, negative
%      {'hfov'}           - horizontal field of view (deg)
%      {'vfov'}           - vertical field of view (deg)
%      {'aspectratio'}    - aspect ratio of image
%      {'height'}*        - image height
%      {'width'}*         - image width
%      {'diagonal'}*      - image diagonal length
%      {'heightandwidth'}*- (height,width)
%      {'area'}*          - optical image area
%      {'centerpixel'}    - (row,col) of point at center of image
%
% Irradiance
%      {'data'}          - Data structure
%        {'photons'}     - Irradiance data
%        {'data max'}     - Used for compression, not for general users
%        {'data min''}    - Used for compression, not for general users
%        {'bit depth''}   - Used for compression, not for general users
%        {'energy'}      - Energy rather than photon representation
%        {'mean illuminance'}  - Mean illuminance
%        {'illuminance'}      - Spatial array of optical image illuminance
%        {'xyz'}         - (row,col,3) image of the irradiance XYZ values
%
% Wavelength information
%      {'spectrum'}     - Wavelength information structure
%        {'binwidth'}   - spacing between samples
%        {'wave'}       - wavelength samples (nm)
%        {'nwave'}      - number of wavelength samples
%
% Resolution
%      {'hspatial resolution'}*   - height spatial resolution
%      {'wspatial resolution'}*   - width spatial resolution    
%      {'sample spacing'}*       - (width, height) spatial resolution
%      {'distance per sample'}*   - (row,col) distance per spatial sample
%      {'distance per degree'}*   - Distance per degree of visual angle
%      {'degreesper distance'}*
%      {'spatial sampling positions'}*   - Spatial locations of points
%      {'hangular resolution'}     - angular degree per pixel in height
%      {'wangular resolution'}     - angular degree per pixel in width
%      {'angular resolution'}      - (height,width) angular resolutions
%      {'frequency Support'}*      - frequency resolution in cyc/deg or
%            lp/Unit, i.e., cycles/{meters,mm,microns}
%            oiGet(oi,'frequencyResolution','mm')
%      {'max frequency resolution'}* - Highest frequency
%            oiGet(oi,'maxFrequencyResolution','um')
%      {'frequency support col','fsupportx'}*  - Frequency support for cols
%      {'frequency support row','fsupporty'}*  - Frequency support for rows
%
% Depth
%     {'depthMap'}   - Pixel wise depth map in meters
%
% Optics information
%      {'optics'}           - See opticsSet/Get
%      {'optics model'}     - diffraction limited, shift invariant, ray
%                             trace
%      {'diffuser method'}   - 'skip','blur' (gaussian),'birefringent'
%      {'diffuser blur'}     - S.D. of Gaussian blur
%
%      {'psfstruct'}        - Entire shift-variant PSF structure
%       {'sampled rt psf'}     - Precomputed shift-variant psfs
%       {'psf sample angles'}  - Vector of sample angle
%       {'psf angle step'}     - Spacing between ray trace angle samples
%       {'psf image heights'}  - Vector of sampled image heights (use optics)
%       {'raytrace optics name'}  - Optics used to derive shift-variant psf
%       {'rt psf size'}        - row,col dimensions of the psf
%
% Misc
%      {'rgb image'}         - RGB rendering of OI data
%
% Copyright ImagEval Consultants, LLC, 2003.


val = [];
if ~exist('parm','var') || isempty(parm), error('Param must be defined.'); end

parm = ieParamFormat(parm);
switch parm
    
    case 'type'
        val = oi.type;
    case 'name'
        val = oi.name;
    case 'filename'
        val = oi.filename;
    case 'consistency'
        val = oi.consistency;
        
       
    case {'rows','row','nrows','nrow'}
        if checkfields(oi,'data','photons'), val = size(oi.data.photons,1);
        else
            % disp('Using current scene rows')
            val = sceneGet(vcGetObject('scene'),'rows');
        end

    case {'cols','col','ncols','ncol'}
        if checkfields(oi,'data','photons'), val = size(oi.data.photons,2);
        else
            % disp('Using current scene cols')
            val = sceneGet(vcGetObject('scene'),'cols');
        end
    case 'size'
        val = [oiGet(oi,'rows'),oiGet(oi,'cols')];
    case {'samplespacing'}
        % Sample spacing, both height and width
        % oiGet(oi,'sample spacing','mm')
        % If no OI is yet computed, we pad the scene size as we would have
        % in the oiCompute calculation.
        sz = oiGet(oi,'size');
        if isempty(sz)
            % This is what the computed OI size will be, given the current
            % scene.
            scene  = vcGetObject('scene');
            sz = sceneGet(scene,'size');
            if isempty(sz), error('No scene or OI'); 
            else 
                padSize  = round(sz/8);
                sz = size(padarray(zeros(sz(1),sz(2)),padSize,0,'both'));
            end
        end
        val = [oiGet(oi,'width')/sz(2) , oiGet(oi,'height')/sz(1)];
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'samplesize'}
        % This is the spacing between samples.  We expect row and column
        % spacing are equal.
        % oiGet(oi,'sample size','mm')
        %
        % Not protected from missing oi data as in 'sample spacing'.
        % Should be integrated with that one.
        w = oiGet(oi,'width');      % Image width in meters
        c = oiGet(oi,'cols');       % Number of sample columns
        val = w/c;                  % M/sample
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'distance','imagedistance','focalplanedistance'}
        % We are finding the distance from the lens to the focal plane.
        % The focal plane depends on the scene distance.  If
        % there is no scene, we assume the user meant a scene at
        % infinity.
        scene = vcGetObject('Scene');
        if isempty(scene), sDist = 1e10;
        else               sDist = sceneGet(scene,'distance');
        end
        val = opticsGet(oiGet(oi,'optics'),'imagedistance',sDist);
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
        
    case {'wangular','widthangular','hfov','horizontalfieldofview','fov'}
        % oiCompute(oi,scene) assigns the angular field of view to the oi.
        % Normally, an OI would not have an angular field of view; it just
        % reflects the angle of the scene it represents.
        if checkfields(oi,'wAngular')
            val = oi.wAngular; 
            if isempty(val)
                % disp('Using current scene angular width')
                val = sceneGet(vcGetObject('scene'),'wangular'); 
            end
        else 
            % disp('Using current scene angular width')
            val = sceneGet(vcGetObject('scene'),'wangular'); 
        end
        
    case {'hangular','heightangular','vfov','verticalfieldofview'}
        % We only store the width FOV.  We insist that the pixels are square       
        h = oiGet(oi,'height');              % Height in meters
        d = oiGet(oi,'distance');            % Distance to lens
        val = ieRad2deg(2*atan((0.5*h)/d));    % Vertical field of view

        
    case {'dangular','diagonalangular','diagonalfieldofview'}
        val = sqrt(oiGet(oi,'wAngular')^2 + oiGet(oi,'hAngular')^2); 

    case 'aspectratio'
        r = oiGet(oi,'rows'); c = oiGet(oi,'cols'); 
        if (isempty(c) || c == 0), disp('No OI'); return; 
        else val = r/c; 
        end

        % Terms related to the optics
        % This is the large optics structure
    case 'optics'
        if checkfields(oi,'optics'), val = oi.optics; end
    case 'opticsmodel'
        if checkfields(oi,'optics','model'), val = oi.optics.model; end
        
        % Sometimes we precompute the psf from the optics and store it
        % here. The angle spacing of the precomputation is specified here
    case {'psfstruct','shiftvariantstructure'}
        % Entire svPSF structure
        if checkfields(oi,'psf'), val = oi.psf; end
    case {'svpsf','sampledrtpsf','shiftvariantpsf'}
        % Precomputed shift-variant psfs
        if checkfields(oi,'psf','psf'), val = oi.psf.psf; end
    case {'rtpsfsize'}
        % Size of each PSF
        if checkfields(oi,'psf','psf'), val = size(oi.psf.psf{1,1,1}); end
    case {'psfsampleangles'}
        % Vector of sample angle
        if checkfields(oi,'psf','sampAngles'), val = oi.psf.sampAngles; end
    case {'psfanglestep'}
        % Spacing between angles
        if checkfields(oi,'psf','sampAngles')
            val = oi.psf.sampAngles(2) - oi.psf.sampAngles(1); 
        end
    case {'psfimageheights'}
        % Vector of sampled image heights
        if checkfields(oi,'psf','imgHeight'), val = oi.psf.imgHeight; end
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
    case {'psfopticsname','raytraceopticsname'}
        % Optics data are derived from
        if checkfields(oi,'psf','opticsName'), val = oi.psf.opticsName; end
    case 'psfwavelength'
        % Wavelengths for this calculation. Should match the optics, I
        % think.  Not sure why it is duplicated.
        if checkfields(oi,'psf','wavelength'), val = oi.psf.wavelength; end

        % optical diffuser properties
  case {'diffusermethod'}
      % 0 - skip, 1 - gauss blur, 2 - birefringent
      if checkfields(oi,'diffuser','method')
          val = oi.diffuser.method;
      end
  case {'diffuserblur'}
      if checkfields(oi,'diffuser','blur')
          val = oi.diffuser.blur;
      end
      if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case 'data'
       if checkfields(oi,'data'), val = oi.data; end;
       
   case {'photons','cphotons'}
       % Read photon data.  
       % Data are returned as doubles (uncompressed).
       if checkfields(oi,'data','photons')
           if isempty(varargin)
               % allPhotons = oiGet(oi,'photons')
               val = oi.data.photons;
           else
               % waveBandPhotons = oiGet(oi,'photons',500)
               idx = ieFindWaveIndex(oiGet(oi,'wave'),varargin{1});
               val = oi.data.photons(:,:,idx); 
           end
       end
       
       % Check if the data are compressed.  If so, uncompress.
       if isa(val,'uint16')
           bitDepth = oiGet(oi,'bitDepth');
           mn = oiGet(oi,'datamin');
           mx = oiGet(oi,'datamax');
           val = ieUncompressData(val,mn,mx,bitDepth);
       end
    
    case {'datamax','dmax'}
        if checkfields(oi,'data','dmax'), val = oi.data.dmax; end
    case {'datamin','dmin'}
        if checkfields(oi,'data','dmin'), val = oi.data.dmin; end
    case {'bitdepth','compressbitdepth'}
        if checkfields(oi,'data','bitDepth'), val = oi.data.bitDepth; end

    case 'energy'
        % Possibly, we should compute the energy from the photons and only
        % store photons.  Otherwise, there could be an inconsistency.
        if checkfields(oi,'data','energy'), val = oi.data.energy; else val = []; end
        
    case {'meanilluminance','meanillum'}
        
        % These aren't saved, just computed.  A bit annoying.  There
        % shouuld be a way to figure out which scene this is, and to save
        % the computation.
        if ~checkfields(oi,'data','illuminance')
            [oi.data.illuminance,oi.data.meanIll] = oiCalculateIlluminance(oi);  
        elseif ~checkfields(oi,'data','meanIll') || isempty(oi.data.meanIll), 
            oi.data.meanIll = mean(oi.data.illuminance(:)); 
        end
        val = oi.data.meanIll;
        
    case {'illuminance','illum'}
        if ~checkfields(oi,'data','illuminance'), val = oiCalculateIlluminance(oi);
        else            val = oi.data.illuminance;
        end
        
                
    case {'xyz','dataxyz'}
        % oiGet(oi,'xyz');
        % 3D array of oi XYZ values.  These are returned as an RGB format
        % at the spatial sampling grid of the optical image.
        photons = oiGet(oi,'photons');
        wave    = oiGet(oi,'wave');
        val     = ieXYZFromEnergy(Quanta2Energy(wave,photons),wave);
        sz = oiGet(oi,'size');
        val = XW2RGBFormat(val,sz(1),sz(2));
         
    case {'spectrum','wavespectrum'}
        if checkfields(oi,'spectrum'), val = oi.spectrum; end
    case 'binwidth'     
        wave = oiGet(oi,'wave');
        if length(wave) > 1, val = wave(2) - wave(1);
        else val = 1;
        end
    case {'wave','wavelength'}
        % oiGet(oi,'wave')
        % There is a problem that the oi spectrum might differ from the
        % optics spectrum.  There should only be one, and it should
        % probably be part of the optics.  To smooth the transition to that
        % wonderful day, I returning the optics spectrum if there is no oi
        % spectrum.
        % Always a column vector, even if people stick it in the wrong way.
        if checkfields(oi,'spectrum'), 
            val = oi.spectrum.wave(:); 
        elseif checkfields(oi,'optics','spectrum'), 
            val = oi.optics.spectrum.wave(:);
        elseif checkfields(oi,'optics','rayTrace','psf','wavelength')
            val = oi.optics.rayTrace.psf.wavelength(:);
        end
    case {'nwave','nwaves'}
        % oiGet(oi,'n wave')
        % Changed July 2012.
        val = length(oiGet(oi,'wave'));
        %         if checkfields(oi,'spectrum'), val = length(oi.spectrum.wave);
        %         elseif strcmp(oiGet(oi,'type'),'opticalimage')
        %             % When the optical image doesn't exist, we can use the scene
        %             % values instead.  But is this a good idea?
        %             val = oiGet(vcGetObject('scene'),'nwave');
        %         end
        
    case 'height'
        % Height in meters is default
        % oiGet(oi,'height','microns')
        val = oiGet(oi,'sampleSize')*oiGet(oi,'rows');       
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
    case {'width'}
        % Width in meters is default - We need to handle 'skip' case 
        d = oiGet(oi,'focalPlaneDistance');    % Distance from lens to image
        fov = oiGet(oi,'wangular');       % Field of view (horizontal, width)
        % ieRad2deg(2*atan((0.5*width)/imageDistance)) = fov
        val = 2*d*tan(ieDeg2rad(fov/2));
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'diagonal','diagonalsize'}
        val = sqrt(oiGet(oi,'height')^2 + oiGet(oi,'width')^2);
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'heightwidth','heightandwidth'}
        val(1) = oiGet(oi,'height');
        val(2) = oiGet(oi,'width');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
     
    case {'area','areameterssquared'}
        % oiGet(oi,'area')    %square meters
        % oiGet(oi,'area','mm') % square millimeters
        val = oiGet(oi,'height')*oiGet(oi,'width');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1})^2; end

    case {'centerpixel','centerpoint'}
        val = [oiGet(oi,'rows'),oiGet(oi,'cols')];
        val = floor(val/2) + 1;
        
    case {'hspatialresolution','heightspatialresolution','hres'}   
        % Resolution parameters
        % Size in distance per pixel, default is meters per pixel
        % oiGet(oi,'hres','microns') is acceptable syntax.
        h = oiGet(oi,'height');
        r = oiGet(oi,'rows');
        if isempty(r) && strcmp(oiGet(oi,'type'),'opticalimage')
            % For optical images we return a default based on the scene.
            % This is used when no optical image has been calculated.
            r = oiGet(vcGetObject('scene'),'rows');
        end
        val = h/r;
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'wspatialresolution','widthspatialresolution','wres'}   
        % Size in m per pixel is default.
        % oiGet(oi,'wres','microns')
        % oiGet(oi,'wres')      
        w = oiGet(oi,'width');
        c = oiGet(oi,'cols');
        if isempty(c) 
            % For optical images we return a default based on the scene.
            % This is used when no optical image has been calculated.
            c = oiGet(vcGetObject('scene'),'cols');
        end
        val = w/c; 
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'spatialresolution','distancepersample','distpersamp'}
        % oiGet(oi,'distPerSamp','mm')
        val = [oiGet(oi,'hspatialresolution'), oiGet(oi,'wspatialresolution')];
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end

    case {'distperdeg','distanceperdegree'}
        % This routine should call 
        % opticsGet(optics,'dist per deg',unit) rather than compute it
        % here.
        val = oiGet(oi,'width')/oiGet(oi,'fov');
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
    
    case {'degreesperdistance','degperdist'}
        % oiGet(oi,'degrees per distance')
        % oiGet(oi,'degPerDist','micron')
        %
        % We should probably call:  
        %   opticsGet(optics,'dist per deg',unit) 
        % which is preferable to this call.
        if isempty(varargin), units = 'm'; else units = varargin{1}; end
        val = oiGet(oi,'distance per degree',units);   % meters
        val = 1 / val;
        % val = oiGet(oi,'fov')/oiGet(oi,'width');
        % if ~isempty(varargin), val = val/ieUnitScaleFactor(varargin{1}); end
        
    case {'spatialsupport','spatialsamplingpositions'}
        % oiGet(oi,'spatialsupport','microns')
        % Spatial locations of points in meters
        sSupport = oiSpatialSupport(oi);
        [xSupport, ySupport] = meshgrid(sSupport.x,sSupport.y);
        val(:,:,1) = xSupport; val(:,:,2) = ySupport;
        if ~isempty(varargin), val = val*ieUnitScaleFactor(varargin{1}); end
        
    case {'angularsupport','angularsamplingpositions'}
        % Angular values of sample points 
        % Units can be deg (default), min or sec and should include radians
        % 
        degPerSamp = oiGet(oi,'angular resolution');
        sz = oiGet(oi,'size');
        
        tmp = degPerSamp(2)*(1:sz(2)); 
        aSupport.x = tmp - mean(tmp(:));
        tmp = degPerSamp(1)*(1:sz(1)); 
        aSupport.y = tmp - mean(tmp(:));
        
        % Deal with units
        if ~isempty(varargin)
            unit = lower(varargin{1});
            switch unit
                case {'deg'} 
                    % Default
                case 'min'
                    aSupport.x = aSupport.x*60;
                    aSupport.y = aSupport.y*60;
                case 'sec'
                    aSupport.x = aSupport.x*60*60;
                    aSupport.y = aSupport.y*60*60;
                case 'radians'
                    aSupport.x = ieDeg2rad(aSupport.x);
                    aSupport.y = ieDeg2rad(aSupport.y);
                otherwise
                    error('Unknown angular unit %s\n',unit);
            end
        end
        
        [xSupport, ySupport] = meshgrid(aSupport.x,aSupport.y);
        val(:,:,1) = xSupport; val(:,:,2) = ySupport;
        % 
    case {'hangularresolution','heightangularresolution'}
        % Angular degree per pixel -- in degrees
        val = 2*ieRad2deg(atan((oiGet(oi,'hspatialResolution')/oiGet(oi,'distance'))/2));
    case {'wangularresolution','widthangularresolution'}
        % Angle (degree) per pixel -- width 
        val = 2*ieRad2deg(atan((oiGet(oi,'wspatialResolution')/oiGet(oi,'distance'))/2));
    case {'angularresolution','degperpixel','degpersample','degreepersample','degreeperpixel'}
        % Height and width
        val = [oiGet(oi,'hangularresolution'), oiGet(oi,'wangularresolution')];
        
    case {'frequencyresolution','freqres'}
        % Default is cycles per degree
        % val = oiGet(oi,'frequencyResolution',units);

        if isempty(varargin), units = 'cyclesPerDegree';
        else units = varargin{1};
        end
        val = oiFrequencySupport(oi,units);
    case {'maxfrequencyresolution','maxfreqres'}
        % Default is cycles/deg.  By using
        % oiGet(oi,'maxfreqres',units) you can get cycles/{meters,mm,microns}
        % 
        if isempty(varargin), units = 'cyclesPerDegree';
        else units = varargin{1};
        end
        % val = oiFrequencySupport(oi,units);
        if isempty(varargin), units = []; end
        fR = oiGet(oi,'frequencyResolution',units);
        val = max(max(fR.fx),max(fR.fy));
    case {'frequencysupport','fsupportxy','fsupport2d','fsupport'}
        % val = oiGet(oi,'frequency support',units);
        if isempty(varargin), units = 'cyclesPerDegree';
        else units = varargin{1};
        end
        fResolution = oiGet(oi,'frequencyresolution',units);
        [xSupport, ySupport] = meshgrid(fResolution.fx,fResolution.fy);
        val(:,:,1) = xSupport; val(:,:,2) = ySupport;   
    case {'frequencysupportcol','fsupportx'}
        % val = oiGet(oi,'frequency support col',units);
        if isempty(varargin), units = 'cyclesPerDegree'; 
        else units = varargin{1};
        end
        fResolution = oiGet(oi,'frequencyresolution',units);
        l=find(abs(fResolution.fx) == 0); val = fResolution.fx(l:end);
    case {'frequencysupportrow','fsupporty'}
        % val = oiGet(oi,'frequency support row',units);
        if isempty(varargin), units = 'cyclesPerDegree'; 
        else units = varargin{1};
        end
        fResolution = oiGet(oi,'frequencyresolution',units);
        l=find(abs(fResolution.fy) == 0); val = fResolution.fy(l:end);
        
        % Computational methods -- About to be obsolete and managed by the
        % optics model information in the optics structure.
    case {'customcomputemethod','oicompute','oicomputemethod','oimethod'}
        if checkfields(oi,'customMethod'), val = oi.customMethod; end
    case {'customcompute','booleancustomcompute'}
        % 1 or 0
        if checkfields(oi,'customCompute'), val = oi.customCompute; 
        else val = 0;
        end
        
        % Visual information
    case {'rgb','rgbimage'}
        % Get the rgb image shown in the window
        % rgb = oiGet(oi,'rgb image',0.6);
        % imwrite(rgb,fName,'tiff')
        
        if isempty(varargin)
            oiW = ieSessionGet('oi window handle');
            if isempty(oiW), gam = 0.6;
            else             gam = str2double(get(oiW.editGamma,'string'));
            end
        else gam = varargin{1}; 
        end
        
        % Render the rgb image
        photons = oiGet(oi,'photons');
        wList   = oiGet(oi,'wave');
        [row,col,nWave] = size(photons);
        photons = RGB2XWFormat(photons);
        val     = imageSPD2RGB(photons,wList,gam);
        val     = XW2RGBFormat(val,row,col);
        
        % Depth information: The depth map in the OI domain indicates
        % locations where there were legitimate scene data for computing
        % the OI data.  Other regions are 'extrapoalted' by sceneDepthRange
        % to keep the calculations correct.  But they don't always
        % correspond to the original data.  When there is no depthMap in
        % the scene, these are all logically '1' (true).
    case {'depthmap'}
        if checkfields(oi,'depthMap'), val = oi.depthMap; end
    case {'logicaldepthmap'}
        % Boolean values indicating locations computed from 
        val = logical(oiGet(oi,'depth map'));
    case {'depthmapphotons'}
        % Get the photons that are within the specified depth map region
        error('Not yet implemented.  See oiCombineDepth for algorithm');
    otherwise
        disp(['Unknown parameter: ',parm]);
        
 end

return;
