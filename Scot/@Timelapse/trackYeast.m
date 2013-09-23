function Timelapse = trackYeast(Timelapse,varargin)
% trackYeast --- %tracking function for whole timelapse
%
% Synopsis:  trackYeastElco(obj)
%
% Input:     Timelapse = an object of a Timelapse3 class
%            
% Output:    Timelapse == an object of a Timelapse3 class

% Notes: Just a holding function that calls a function given by
% Timelapse.defaults.trackfunction.

%get the appropriate parameters

param = parseParamsTrackYeast(Timelapse,varargin{:});

%create handle to the desired tracking function 
track_func_handle = str2func(['trackyeastmethods.' param.trackfunction]);

%call tracking function.

Timelapse = track_func_handle(Timelapse);

end

  
                 
      