function ScoreMat = template_SF(Timelapse,TNnow,TNpast,tnow,tpast,paramScoreFnc)

% distance_SF ---     a score function for the loop_timpoints function.
%                     
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
%                     tpas = the 'past' timpoints i.e. the one to which the
%                            cells in the current timepoint are being compared in
%                            order to identify their cell numbers
%                     paramScoreFnc = a cell array of parameters for the function
                      
%                                   
%
% Output:             ScoreMat == a TNpast x TNnow matrix of scores

% Notes: this is a template for a score function that can be called by the loop_timepoints
% tracking function (which is itself called by the trackYeast Timelapse
% method) Timlapse method. It should take inputs as described above and return a score matrix of the standard form for
% a loop_timepoints score function. that is:

%ScoreMat is a [tracking numbers at previous timepoint]x[tracking numbers
% %at current timepoint] ScoreMat(i,j) = the 'score' for cell TNnow(j) at the
% current timepoint,tnow, and cell TNpast(i) at the 'past' timpoint ,tpast.
% Score should have the property:
% Positive real number = a score to be compared with other real numbers to
% too see if cell TNnow(i) should be given one cell number in use at the
% timepoint tpast or another. higher score -> more likely to be that cell
% -1 = assign a new cell number to this score.
% -2 = pass to the cell to the timepoint previous to this one and look there for a cell number
