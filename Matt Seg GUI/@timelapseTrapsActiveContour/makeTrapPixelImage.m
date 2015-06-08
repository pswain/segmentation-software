function ttacObject = makeTrapPixelImage(ttacObject,f2)
%calls the makeTrapPixelsFunction to make the trap pixels. Written in this
%way in case there is cause to one day elaborate to more functions.

if nargin<2
    ttacObject.TrapPixelImage = ACTrapFunctions.makeTrapPixelsFunction(ttacObject.TrapImage);
else
    ttacObject.TrapPixelImage=imfilter(double(ttacObject.TrapImage),f2);
    ttacObject.TrapPixelImage=ttacObject.TrapPixelImage/max(ttacObject.TrapPixelImage(:))*.85;
end