%Experiment curation.
%By Luis Montano, Swain Lab
%2014 07 18
%Last update: october 2014

%This set  of functions allow you to do curation of your cExperiment based on individual tracks of cells. That is, 
%you can click on individual tracks and either...
%a) display a video of the selected cell to monitor it through the images 
%		Howto:
		%1. plot some cell information feature of your cells in the experiment, like with the following line:
      
      figure(); plot(cExperiment.cellInf(2).mean')
      
      %2. type the command "plotedit on" to open the plot edition interface in your figure. this allows you to click on lines (ie cells' tracks )
      %3. click on a cell (ie a line) that follows a pattern of your interest.
      %4. when you are done clicking, type:
     
selectedCellVideo(cExperiment, gcf, channel)
%in this case we use gcf to refer to the last figure we clicked on, but should you have a handle for the figure you want, just
      %use that handle name. 
      %channel is the channel that you want to display (1 for DIC, 2 normally for main cell fluorescence (like GFP or mCherry) 
 %     and 3 normally for background fluorescence (like fluorescein or cy5)



%(this is useful for knowing whether the data observed arise from segmentation errors).
%b) Explore whether subsets of cells follow different patterns, and to explore whether those patterns 
%are caused by a change in the imaging conditions, in the input, in the segmentation or in the size of the cell.

              Howto:

      %1. plot some cell information feature of your cells in the experiment, like with the following line:
      
      figure(); plot(cExperiment.cellInf(2).mean')
      
      %2. type the command "plotedit on" to open the plot edition interface in your figure. this allows you to click on lines (ie cells' tracks )
      %3. find tracks that you think follow characteristic patterns. click on one cell track or click on several ones by holding shift. 
      %4. when you are done clicking, type:
     
      selectedCellKmeans(cExperiment, gcf)
      
      %in this case we use gcf to refer to the last figure we clicked on, but should you have a handle for the figure you want, just
      %use that handle name.
      %you can modify the call to kmeans to cluster cells in the way you find more reasonable (See help for kmeans)
      
      %NOTE: the functions assume:
       %channels are 1 for DIC, 2 for main cell fluorescence (like GFP or mCherry) 
    %  and 3 for background fluorescence (like fluorescein or cy5) 
      
     % 5. You will get a nice graph plotting different kinds of information per cluster. 

            