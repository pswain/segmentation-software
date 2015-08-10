function ScoreMat = distance_SF(Timelapse,TNnow,TNpast,tnow,tpast,paramScoreFnc)

% distance_SF ---     a score function for the loop_timpoints function.
%                     Score return is 2*(image size)^2 - (distance between cells)^2. Chosen
%                     since it was a positive, monotonically decreasing function of distance.

% Synopsis:           distance_SF(Timelapse,TNnow,TNpast,tnow,tpast,paramScoreFnc)
%

% Input:              Timelapse = an object of a Timelapse3 class
%                     TNnow = a vector of the tracking numbers of the 
%                             cells at timepoint tnow for which score is 
%                             to be returned.
%                     TNpast = a vector of the tracking numbers of the 
%                              cells at timepoint tpast for which score is 
%                              to be returned.
%                     tnow = the 'current' timpoint i.e. the one for which
%                            cell numbers are trying to be found.
%                     tpast = the 'past' timpoints i.e. the one to which the
%                            cells in the current timepoint are being compared in
%                            order to identify their cell numbers
%                     paramScoreFnc = a cell array of parameters for the function%
%                                   = {Thresh}
%                                   = the maximum distance between cells
%                                     before the are deemed not to be the
%                                     same cell.

%
% Output:             ScoreMat == a TNpast x TNnow matrix of scores

% Notes: a score function that can be called by the loop_timepoints
% tracking function (which is itself called by the trackYeast Timelapse
% method) Timlapse method. returns a score matrix of the standard form for
% a loop_timepoints score function.(see the loop_timpoints for details or
% the template_SF score function in the LoopScoreFuntions package.

Nnow = length(TNnow);
Npast = length(TNpast);
thresh = paramScoreFnc{1}; %threshold separation above which two cells are deemed not to be connected.

%coordinates of cells of interests at timpoint tnow
Xnow = [Timelapse.TrackingData(tnow).cells(TNnow).centroidx] ;
Ynow = [Timelapse.TrackingData(tnow).cells(TNnow).centroidy];
Xnow=double(Xnow);
Ynow=double(Ynow);

%coordinates of cells of interests at timpoint tpast
Xpast = [Timelapse.TrackingData(tpast).cells(TNpast).centroidx];
Ypast = [Timelapse.TrackingData(tpast).cells(TNpast).centroidy];
Xpast=double(Xpast);
Ypast=double(Ypast);

Xpast = Xpast'*ones(1,Nnow);
Ypast = Ypast'*ones(1,Nnow);

Xnow = ones(Npast,1)*Xnow;
Ynow = ones(Npast,1)*Ynow;

ScoreMat = Score(Timelapse,Xnow,Ynow,Xpast,Ypast);

ThreshScore = Score(Timelapse,thresh,0,0,0);

ScoreMat(ScoreMat<=ThreshScore) = -2;


end


function ScoreMat = Score(Timelapse,Xnow,Ynow,Xpast,Ypast)

%calculates the score for each pair of elements in the matrices.

ScoreMat = 2*sum((Timelapse.ImageSize).^2 ,2) - ((Xnow - Xpast).^2 + (Ynow - Ypast).^2);
%initial part is to ensure score i always positive. 2nd part is subtraction of euclidean
%distance of centers, giving a smaller score for cells further apart.


end

