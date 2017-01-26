function slider_cb(cDisplay)
timepoint = get(cDisplay.slider,'Value');
timepoint=floor(timepoint);

image=cDisplay.cTimelapse.returnSingleTimepoint(timepoint,cDisplay.channel);
image = 0.95*SwainImageTransforms.min_max_normalise(image);
image=repmat(image,[1 1 3]);


set(cDisplay.subImage,'CData',image);
set(cDisplay.figure,'Name',['Timepoint ' int2str(timepoint) ...
                            ' , channel ' cDisplay.cTimelapse.channelNames{cDisplay.channel}...
                            '   [index ' sprintf('%d',cDisplay.channel) ']']);
