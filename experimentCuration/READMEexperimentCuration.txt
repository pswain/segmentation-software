Experiment curation.

This set  of functions allow you to do curation of your cExperiment based on individual tracks of cells. That is, 
you can click on individual tracks and either...
a) display a video of the selected cell to monitor it through the images 
(this is useful for knowing whether the data observed arise from segmentation errors).
b) Explore whether subsets of cells follow different patterns, and to explore whether those patterns 
are caused by a change in the imaging conditions, in the input, in the segmentation or in the size of the cell.

              Howto:

      1. plot some cell information feature of your cells in the experiment, like with the following line:
      
      figure(); plot(segmentation20140520.cExperiment.cellInf(2).mean')
      
      2. type the command "plotedit on" to open the plot edition interface in your figure. this allows you to click on lines (ie cells' tracks )
      3. find tracks that you think follow characteristic patterns. click on one cell track or click on several ones by holding shift. 
      4. when you are done clicking, type:
     
      selectedCellKmeans(cExperiment, gcf)
      
     % in this case we use gcf to refer to the last figure we clicked on, but should you have a handle for the figure you want, just
      %use that handle's name.
            