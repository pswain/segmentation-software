function obj=placeResultInRegion(obj,smallResult)

    if isempty (obj.CatchmentBasin)~=1%the cell is split - ie this is worth doing
        resultInRegion=false(size(obj.ThisCell));
        resultInRegion(obj.TopLeftThisCelly:obj.TopLeftThisCelly+obj.yThisCellLength-1,obj.TopLeftThisCellx:obj.TopLeftThisCellx+obj.xThisCellLength-1)=smallResult;
        obj.Result=resultInRegion;
    else
        obj.Result=smallResult;

    end
    if isempty(obj.ImageSize)~=1
        obj.FullSizeResult=false(obj.ImageSize);
        obj.FullSizeResult(obj.TopLefty:obj.TopLefty+obj.yLength-1,obj.TopLeftx:obj.TopLeftx+obj.xLength-1)=obj.Result;
    end
end