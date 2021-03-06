function [sOBJECT,val] = vcGetObject(objType,val)
%Retrieve an object from vcSESSION structure
%
%   [sOBJECT,val] = vcGetObject(objType,val)
%
%Purpose:
%   Find the currently selected object of the various possible types:
%
%      SCENE, PIXEL, OPTICS, {OPTICALIMAGE,OI}, {IMGPROC,VCIMAGE,VCI}, GRAPHWIN,
%      {ISA,SENSOR}
%
% This routine replaces: [val,sOBJECT] = vcGetSelectedObject('SCENE');
%
% The new call is shorter as in:
%
%  obj = vcGetObject('SCENE');
%  pixel = vcGetObject('PIXEL')
%  vci = vcGetObject('VCIMAGE')
%  vci = vcGetObject('IMGPROC')
%  oi = vcGetObject('OI')
%
%  If you need the val, you can still use
%
%    [obj,val] = vcGetObject('SCENE');
%
% Copyright ImagEval Consultants, LLC, 2003.

global vcSESSION

objType = vcEquivalentObjtype(objType);
if ieNotDefined('val'), val = vcGetSelectedObject(objType); end

if ~isempty(val)
    switch(lower(objType))
        case {'scene','isa','opticalimage','vcimage'}
            eval(['sOBJECT = vcSESSION.',objType,'{val};']);
        case {'pixel'}
            sOBJECT = sensorGet(vcSESSION.ISA{val},'pixel');
        case {'optics'}
            sOBJECT = oiGet(vcSESSION.OPTICALIMAGE{val},'optics');
        case {'display'}
            sOBJECT = vcimageGet(vcSESSION.VCIMAGE{val},'display');
        otherwise
            error('Unknown object type.');
    end
else
    sOBJECT = [];
end

return
