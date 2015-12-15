function handles=makeRegionStacks(handles)

      x=handles.region(1);
    y=handles.region(2);
    xl=handles.region(3);
    yl=handles.region(4);
    handles.regionTarget=handles.mainImages(y:yl+y-1,x:xl+x-1,:,:);
    handles.regionMerged=handles.fullSizeMerged(y:yl+y-1,x:xl+x-1,:,:);
    handles.regionBinary=handles.cellResultStack(y:y+yl-1,x:x+xl-1,:);
    %Make sure that no rgb images have values>1
    handles.fullSizeMerged(handles.fullSizeMerged>1)=1;
end