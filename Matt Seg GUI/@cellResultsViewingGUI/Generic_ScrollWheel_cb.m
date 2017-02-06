function Generic_ScrollWheel_cb(GUI,src,event,property)
% Generic_ScrollWheel_cb(GUI,src,event)
%
% GUI       :   a GUI object
% property  :   defaut 'slider'. The property of GUI in which a slider
%               object is stored.
%
% A generic scroll wheel call back for any GUI/axis with a slider. Will
% simply change the value of the slider according to how the scroll wheel
% was rolled. Can be implemented by inserting the line:
%
% set([GUI figure],'WindowScrollWheelFcn',@(src,event)Generic_ScrollWheel_cb(GUI,src,event,[property]));
%
% where [GUI figure] is the figure handle of the figure which the GUI is in
% and slider is the property of the GUI storing a handle of the slder
% object.
% 

if nargin<4 || isempty(property)
    property = 'slider';
end


SliderValue = get(GUI.(property),'Value');

SliderValue = SliderValue + event.VerticalScrollCount;

if SliderValue< get(GUI.(property),'Min')
    SliderValue = get(GUI.(property),'Min');
end


if SliderValue> get(GUI.(property),'Max')
    SliderValue = get(GUI.(property),'Max');
end

set(GUI.(property),'Value',SliderValue);


end

