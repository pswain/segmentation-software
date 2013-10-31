function cDisplay_ScrollWheel_cb(cDisplay,src,event)
% cDisplay_ScrollWheel_cb(cDisplay,src,event)
%   Call back for the scroll wheel function. 

SliderValue = get(cDisplay.slider,'Value');

SliderValue = SliderValue + event.VerticalScrollCount;

if SliderValue< get(cDisplay.slider,'Min')
    SliderValue = get(cDisplay.slider,'Min');
end


if SliderValue> get(cDisplay.slider,'Max')
    SliderValue = get(cDisplay.slider,'Max');
end

set(cDisplay.slider,'Value',SliderValue);


end

