function AlterOutlineFromGivenPoint(ttacObject,Timepoint,TrapIndex,CellIndex,GivenPoint)

%Cx Cy expected to be relative with positive Cx indicating GivenPoint is right of center
%and positive Cy indicating GivenPoint is below center.

if any(GivenPoint ~= 0)
    
    GivenPointx = GivenPoint(1);
    GivenPointy = GivenPoint(2);
    
    Radii = ttacObject.ReturnCellRadii(Timepoint,TrapIndex,CellIndex);
    
    Angles = ttacObject.ReturnCellAngles(Timepoint,TrapIndex,CellIndex);
    
    [Rnew,angle_new] = ACBackGroundFunctions.xy_to_radial(GivenPointx,GivenPointy);
    
    [~,minindex] = min(abs([Angles';(2*pi)] - angle_new));
    
    if minindex==(length(Radii)+1)
        minindex=1;
    end
    
    Radii(minindex) = Rnew;
    
    ttacObject.WriteACResults(Timepoint,TrapIndex,CellIndex,Radii,Angles);
    
end
end