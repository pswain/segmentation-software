function help_string = active_contour_parameters( )
% This is a documentation for the rough meaning of the parameters passed to
% the active contour method.
% experimentTracking.ActiveContourParameters contains a number of
% structures, each of which has a different set of parameters.
% 
% TrapDetection - structure of parameters for identifying the trap pixels
%                 in the image. 
%   .channel    - array of trap indices the chanel used to detect trap
%                 pixels in the image. The actual image used is a
%                 normalised sum of the indices, and if an index is
%                 negative then that image will be inverted before summing.
%                 This is done in the
%                 timelapseTraps.generateSegmentationImages method.
%                 Defaults to timelapseTraps.channelForTrapDetection.
%   .function   - string : the name of the function (in the
%                 ActiveContourFunctions.+ACTrapFunctions package) applied
%                 to the images to get the trap pixel. Default is
%                 'simpleThreshold'.
%   .functionParams - structure : the parameter structure of this funtion. 
%                     See the function itself for the structure and function of
%                     these parameters.
%
% ImageTransformation - structure of parameters for producing the edge image
%                       that will be used in the active contour method for
%                       detecting edges. It is now common to use the output
%                       from the cellVision model, and so most of these
%                       parameters are often unused.
%   .EdgeFromDecisionImage - boolean : if true, then the decision image
%                            result is used to generate the edge image
%                            for the active contour method. If false, the
%                            transform/channel described below is used.
%   .pTrapIsCentreEdgeBG - array: When the edge image is generated from the
%                          decision image, trap edge pixels (i.e. those
%                          pixels in the trap score image with a trap score
%                          between 0.5 and 1) are handled explicitly, and
%                          are given and edge/centre/background score. This
%                          array is the score given to them expressed as
%                          the probability vectpr [p_cell_centre,
%                          p_cell_edge, p_background], so any trap edge
%                          pixel is given this probability vector.
%   .normalisation - string : I think this is now defunct but I have left
%                             if it in because I am too lazy to be sure.
%   .channel    - array of trap indices of the channels used to construct
%                 the edge image. The actual image used is a
%                 normalised sum of the indices, and if an index is
%                 negative then that image will be inverted before summing.
%                 This is done in the
%                 timelapseTraps.generateSegmentationImages method. This is
%                 only used if .EdgeFromDecisionImage is false.
%   .ImageTransformFunction   - string : the name of the function (in the
%                               ActiveContourFunctions.+ACImageTransformations
%                               package) applied to the images to get the
%                               edge image. Default is'radial_gradient'.
%                               This is only used if .EdgeFromDecisionImage
%                               is false.
%   .TransformParameters - structure : the parameter structure of this
%                          function. See the function itself for the
%                          structure and function of these parameters.
%
% ActiveContour : This, together with CrossCorrelation, is the
%                 structure of parameters used in detecting cells and edge
%                 once the decision image, edge image and trap image have
%                 been produced.
%   .alpha - float : the weight of the shape term used in the active
%            contour method when determining the outline of new cells.
%   .beta  - float : the weight of the change of shape in time term used in
%            the active contour method when determining the outline of
%            tracked cells.
%   .R_min - integer : the smallest allowed radii for the cell.
%   .R_max - integer : the largest allowed radii for the cell.
%   .opt_points - integer : the number of radii used in determining the
%                 cell outline. Defaults to 6, and has to match that
%                 assumed in the cellMorphologyModel. There is a section in
%                 MorphologyModelTrainingScript.m on how to get around this
%                 for new cellMorphology models.
%   .visualise - integer : if set to a number above 0 it will show some
%                diagnostic information such as intermediary images.
%   .ShowChannel - integer : channel index to show in the display GUI while
%                  segmenting.
%   .TrapPixExclideThreshAC - float : The trap processing described above
%                             produces a n image where each pixel is given
%                             a proabability of being a trap pixel. Pixels
%                             above (or equal to) this threshold are
%                             forcible excluded from cell interiors.
%   .CellPixExcludeThresh - float : after a cell is detected, a distance
%                           transform is performed on it and normalised.
%                           Any values above this threshold in that image
%                           are forcibly excluded from the interior of cell
%                           subsequently found.
%   .MaximumRadiusChange - float : maximum allowed change in any single
%                          radii between 1 timepoint and the next. Defaults
%                          to Inf.
%   .inflation_weight   - float : multiplies the inflation term that forces
%                         cells not to be too small, so bigger leads to
%                         bigger cells.
%   .optimisation_paramters - structure of parameters passed to
%                             +ACMethods.spline_grad_search (optimiser used
%                             in finding the outline).
%
% CrossCorrelation : This, together with ActiveContour, is the structure of
%                    parameters used in detecting cells and edge once the
%                    decision image, edge image and trap image have been
%                    produced.
%   .CrossCorrelationValueThreshold - float (>=0) : threshold probability a
%                                     pixel must pass to  be analysed as a
%                                     tracked cell centre. Defaults to 0,
%                                     so no longer used in preference for
%                                     CrossCorrelationDIMthreshold.
%   .CrossCorrelationDIMthreshold - threshold in the decision image that a
%                                   pixel must be over to be considered as
%                                   a tracked cell centre. Should be higher
%                                   than twoStageThresh.
%   .twoStageThres - threshold in decision image that a pixel must be over
%                    to be considered as a new cell centre. 
%   .PostCellIdentificationDilateValue - after detection, a dilated cell
%                                        mask is 'blotted out' of the
%                                        decision image so that no new cell
%                                        centres (or tracked cell centres)
%                                        will be found there. This value is
%                                        the number of pixels the cell
%                                        outline is dilated before this
%                                        occurs. If it is negative, the
%                                        outline is instead eroded. Default
%                                        is 2, so no cell centre will be
%                                        detected within 2 pixels of an
%                                        already occurring cell centre.
%   .PerformRegistration - boolean : if processing a non-trap timelapse,
%                          the sofware can register the image between
%                          timepoints to try and compensate for big shifts
%                          in focus. This is done if this flag is true.
%   .MaxRegistration - integer : if the above is true, this is the maximum
%                      amount the image will be shifted between timepoints.
%   .MotionPriorSmoothParameters - the motion prior is the probability of a
%                                  cell moving to a given pixel from it's
%                                  current location. This is based on a
%                                  trained motion prior, but is smoothed
%                                  for better performance. This is the
%                                  smoothing parameter, an array of the
%                                  [standard deviation, maximum_allowed_move] in
%                                  pixels.
%   .StrictMotionPriorSmoothParameters - as above but stricter (so smaller
%                                        standard deviation). Used for
%                                        checking cells after they are
%                                        detecting and making sure they
%                                        don't make crazy jumps.
%   .ThresholdCellProbability - When a tracked cell is detected, a bayes
%                               factor of its tracked_cell_probability and
%                               it's new_cell_probability is calculated. If
%                               this is below ThresholdCellProbability, the
%                               tracked cell is discarded (on the
%                               assumption that the cell is then much more
%                               likely to be a new cell). defaults to
%                               2e-30.
%   .ThresholdCellScore - When a new cell is detected, its score from the
%                         active contour cost functions is compared to this
%                         threshold. If it is above this threshold, it is
%                         discarded.

help_string = help('HelpHoldingFunctions.active_contour_parameters');


end

