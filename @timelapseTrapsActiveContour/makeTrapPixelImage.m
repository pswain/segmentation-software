function ttacObject = makeTrapPixelImage(ttacObject)
%calls the makeTrapPixelsFunction to make the trap pixels. Written in this
%way in case there is cause to one day elaborate to more functions.

ttacObject.TrapPixelImage = ACTrapFunctions.makeTrapPixelsFunction(ttacObject.TrapImage);

end