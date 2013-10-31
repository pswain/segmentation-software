function curateCellTrackingGUI_ScrollWheel_cb(TrackingCurator,src,event)
% editActiveContourCell_ScrollWheel_cb(TrackingCurator,src,event)
%   Call back for the scroll wheel function. 

SliderValue = get(TrackingCurator.slider,'Value');

SliderValue = SliderValue + event.VerticalScrollCount;

if SliderValue< get(TrackingCurator.slider,'Min')
    SliderValue = get(TrackingCurator.slider,'Min');
end


if SliderValue> get(TrackingCurator.slider,'Max')
    SliderValue = get(TrackingCurator.slider,'Max');
end

set(TrackingCurator.slider,'Value',SliderValue);


end

