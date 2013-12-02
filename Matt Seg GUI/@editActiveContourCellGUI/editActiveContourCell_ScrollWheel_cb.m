function editActiveContourCell_ScrollWheel_cb(CellACDisplay,src,event)
% editActiveContourCell_ScrollWheel_cb(CellACDisplay,src,event)
%   Call back for the scroll wheel function. 

SliderValue = get(CellACDisplay.slider,'Value');

SliderValue = SliderValue + event.VerticalScrollCount;

if SliderValue< get(CellACDisplay.slider,'Min')
    SliderValue = get(CellACDisplay.slider,'Min');
end


if SliderValue> get(CellACDisplay.slider,'Max')
    SliderValue = get(CellACDisplay.slider,'Max');
end

set(CellACDisplay.slider,'Value',SliderValue);


end

