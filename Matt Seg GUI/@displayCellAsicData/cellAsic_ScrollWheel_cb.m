function cellAsic_ScrollWheel_cb(GUI,src,event)
% Generic_ScrollWheel_cb(GUI,src,event)

% A generic scroll wheel call back for any GUI/axis with a slider. Will
% simply change the value of the slider according to how the scroll wheel
% was rolled. Can be implemented by inserting the line:

% set([GUI figure],'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(GUI,src,event));

%where [GUI figure] is the figure handle of the figure which the GUI is in
%(often we set this to be a property of the GUI object). 


SliderValue = get(GUI.timepointSlider,'Value');

SliderValue = SliderValue + event.VerticalScrollCount;

if SliderValue< get(GUI.timepointSlider,'Min')
    SliderValue = get(GUI.timepointSlider,'Min');
end


if SliderValue> get(GUI.timepointSlider,'Max')
    SliderValue = get(GUI.timepointSlider,'Max');
end

set(GUI.timepointSlider,'Value',SliderValue);


end
