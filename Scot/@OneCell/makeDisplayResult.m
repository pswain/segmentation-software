function resultStack=makeDisplayResult (obj)
    % makeDisplayResult --- Creates a displayable stack of full size 2d result images for the currently-selected cell
    %
    % Synopsis:  obj = makeDisplayResult (obj)
    %
    % Input:     obj = an object of a OneCell class
    %
    % Output:    obj = an object of a OneCell class

    % Notes: This should be run after any change in the result images or
    %        currently-selected cell number.
    
    trackingnumbers=obj.Timelapse.getTrackingNumbers(obj.cellnumber);
    resultStack=false(obj.Timelapse.ImageSize(2), obj.Timelapse.ImageSize(1),size(trackingnumbers,2));
    for t=1:size(trackingnumbers,2)
        if trackingnumbers(t)>0
            resultStack(:,:,t)=obj.Timelapse.Result(:,:, trackingnumbers(t), t);
        end
    end

end