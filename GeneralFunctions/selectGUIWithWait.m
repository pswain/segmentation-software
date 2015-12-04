function out = selectGUIWithWait(duration,prompt_text,title,text_1,text_2)
%out = selectGUIWithWait(duration,title,prompt_text,text_1,text_2)
%
% a two option GUI that will dissapear after a fixed duration.
%
% duration      :   time before GUI closes itself
% prompt_text   :   prompt text tp explain what the two options will do
% title         :   title of GUI
% text_1        :   text on left button (default 'yes')
% text_2        :   text on right button (default 'no')
%
% out           :   0 if GUI ran duration without user input
%                   1 if button 1 (yes) pushed
%                   2 if button 2 (no) pushed
% uses a 

if nargin<3 || isempty(title)
    title = '';
end


if nargin<4 || isempty(text_1)
    title = 'Yes';
end

if nargin<5 || isempty(text_2)
    title = 'No';
end

scrsz = get(0,'ScreenSize');

%fix size and position of GUI
figh=figure('MenuBar','none','Position',[scrsz(3)/3 scrsz(4)/3 400 200]);

% create structure of handles
myhandles = guihandles(figh); 
% Add some additional data as a new field called numberOfErrors
myhandles.out = 0; 
% Save the structure
guidata(figh,myhandles) 

set(figh,'Name',title);

% timer object to close gui and leave out as 1 if duration elapses
timer_obj = timer('StartDelay',duration,'TasksToExecute',1,'TimerFcn',{@set_out,figh,0});

start(timer_obj);

t = uicontrol('Parent',figh,...
            'Style','text',...
            'String',prompt_text,...
            'Units','normalized',...
            'HorizontalAlignment','left',...
            'Position',[0.025 0.35 0.95 0.6]);
        
b1 = uicontrol(figh,'Style','pushbutton','String',text_1,...
                'Units','normalized',...
                'Position',[.025 .05 .45 .3],...
                'Callback',{@set_out,figh,1});
            
b2 = uicontrol(figh,'Style','pushbutton','String',text_2,...
                'Units','normalized',...
                'Position',[.525 .05 .45 .3],...
                'Callback',{@set_out,figh,2});

uiwait(figh);
    
stop(timer_obj);
delete(timer_obj);
myhandles = guidata(figh); 
out = myhandles.out; 
close(figh)


end

function set_out(obj,event,figh,out_value)

myhandles = guidata(figh); 
% Add some additional data as a new field called numberOfErrors
myhandles.out = out_value; 
% Save the structure
guidata(figh,myhandles) 

uiresume(figh);
end

