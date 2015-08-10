function obj=bridgeEdges(obj)
    % bridgeEdges --- attempts to fill gaps in all edge-based images associtated with a OneCell object
    %
    % Synopsis:  obj = bridgeEdges (obj)
    %                        
    % Input:     obj= an object of a OneCell class
    %
    % Output:    obj= an object of a OneCell class

    % Notes:     For use during editing of segmentation to see the effect
    %            of bridging.
    
    obj.EdgeImage=bwmorph(obj.EdgeImage,'Bridge');
    obj.EdgeImage=bwmorph(obj.AbsEdgeImage,'Bridge');
    obj.EdgeImage=bwmorph(obj.OuterRemoved,'Bridge');
    obj.EdgeImage=bwmorph(obj.OuterRemovedAbs,'Bridge');
    obj.EdgeImage=bwmorph(obj.OuterImage,'Bridge');
    obj.EdgeImage=bwmorph(obj.OuterImageAbs,'Bridge');
end