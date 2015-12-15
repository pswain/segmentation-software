function changeActiveContourButtonState(cTrapsGUI)
% changeActiveContourButtonState(cTrapsGUI) a simple call back to change
% the string on the ActiveContourButton.

if cTrapsGUI.ActiveContourButtonState == 1
    set(cTrapsGUI.ActiveContourButton,'String', 'Inst. Active Cont.')
elseif cTrapsGUI.ActiveContourButtonState == 2
    set(cTrapsGUI.ActiveContourButton,'String', 'Run Active Cont.')
end

end

