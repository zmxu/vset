function oi = opticsDLCompute(scene,oi)
%Diffraction limited optical image computation
%
%   oi = opticsDLCompute(scene,oi)
%
% The diffraction limited optical image calculation uses only a few
% parameters (f-number, focal length) to calculate the optical image.  The
% diffraction limited OTF is calculated on the fly in dlMTF, and applied to
% the scene image in this routine.
%
% See also:  oiCompute, opticsSICompute, opticsRayTrace
%
% Examples:
%  We don't normally call this function directly.  We use oiCompute which
%  then makes the appropriate call based on how the optics model is set.
%
% Copyright ImagEval Consultants, LLC, 2005

% TODO:  We should insert a geometric distortion function in this code,
% rather than using it only in the ray trace methods. 
if ieNotDefined('scene'), scene = vcGetObject('scene'); end
if ieNotDefined('oi'),    oi = vcGetObject('oi');       end

optics = oiGet(oi,'optics');
opticsModel = opticsGet(optics,'model');
if ~(strcmpi(opticsModel,'dlmtf') || ...
        strcmpi(opticsModel,'diffractionlimited') || ...
        strcmpi(opticsModel,'skip'))
    error('Bad DL optics model %s',opticsModel);
elseif strcmpi(opticsModel,'dlmtf') ||  strcmpi(opticsModel,'diffractionlimited')
    wStr = 'OI-DL: ';
else
    wStr = 'Skip OTF: ';
end

% Compute the basic parameters of the oi from the scene parameters.
oi = oiSet(oi,'wangular',sceneGet(scene,'wangular'));
oi = oiSet(oi,'spectrum',sceneGet(scene,'spectrum'));

%  There really shouldn't be both a scene and an optical image spectrum. Or
%  at least, they should always be linked. Not sure what to do at this
%  point.  If this is the only time we ever set the optics spectrum, then
%  we have enforced the equality.  But just by having the variable, people
%  can create an inconsistency.  Think.
optics = opticsSet(optics,'spectrum',oiGet(oi,'spectrum'));
oi     = oiSet(oi,'optics',optics);

% Calculate the irradiance of the optical image in photons/(s m^2 nm)

wBar = waitbar(0,[wStr,' Calculating irradiance...']);
oi   = oiSet(oi,'cphotons',oiCalculateIrradiance(scene,optics));
% vcAddAndSelectObject(oi); oiWindow;

% Here, we need to insert a distortion function. This should be a button on
% the window that let us indicate that we want the distortion computed.
% Which point in the computation should have the distortion?  Before or
% after application of the OTF?
%
% DISTORTION?  See Peter and remember Patrick conversation
%
waitbar(0.3,wBar,[wStr,' Calculating off-axis falloff']);

% Now apply the offaxis fall-off.
% We either apply a standard cos4th calculation, or we use the more
% elaborate relative illumination derived from CodeV. stored inside of
% data\optics\Lens Design\Standard.
offaxismethod = opticsGet(optics,'offaxismethod');
switch lower(offaxismethod)
    case {'skip','none',''}
    case 'cos4th'
        oi = opticsCos4th(oi);
    otherwise
        fprintf('\n-----\nUnknown offaxis method: %s.\nUsing cos4th instead.',optics.offaxis);
        oi = opticsCos4th(oi);
end

% We apply the MTF here.
switch lower(opticsGet(optics,'model'))
    case 'skip'
    case {'dlmtf','diffractionlimited'}
        waitbar(0.6,wBar,[wStr,' Applying OTF']);
        oi = opticsOTF(oi,scene);
    otherwise
        error('Unknown optics model %',opticsGet(optics,'model'))
end

% Diffuser and illuminance, or just illuminance.  Diffuser always resets
% the illuminance, which seems proper.
switch lower(oiGet(oi,'diffuserMethod'))
    case 'blur'
        waitbar(0.75,wBar,[wStr,' Diffuser']);
        blur = oiGet(oi,'diffuserBlur','um');
        if ~isempty(blur), oi = oiDiffuser(oi,blur); end
    case 'birefringent'
        waitbar(0.75,wBar,[wStr,' Birefringent Diffuser']);
        oi = oiBirefringentDiffuser(oi);
    case 'skip'
        
end

% Compute image illuminance (in lux)
waitbar(0.9,wBar,[wStr,' Calculating illuminance']);
oi = oiSet(oi,'illuminance',oiCalculateIlluminance(oi));

delete(wBar)

return;