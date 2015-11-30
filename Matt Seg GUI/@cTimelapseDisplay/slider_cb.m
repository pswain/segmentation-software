function slider_cb(cDisplay)
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);

image=cDisplay.cTimelapse.returnSingleTimepoint(timepoint,cDisplay.channel);
image=double(image);
image=image/max(image(:))*.95;
image=repmat(image,[1 1 3]);


set(cDisplay.subImage,'CData',image);
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint)]);
