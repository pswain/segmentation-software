    

    

displayCellAsicData 
--------------------------------------------------------------


      Class to track the concentration of GFP in the nucleus of a
      cell. Designed to be a sub-class of experimentTrackingGUI, and expects
      data in the form that the timelapseTraps functions produce.
      
    Data about 

      Concentration of GFP is defined by max5/median pixel brightnes,
      where max5 is the mean brightnes of the 5 brightest pixels.
    
      Areas which do not support traps:
          Image displays as a single large image, not series of smaller
          images
          Cells are tracked using find(), rather than this where cellNum
          is included in extracted data.
    
      NOTE: Does not currently support traps
      
      KEY VARS:       cellsToPlot: 100x100 sparse matrix
                        Copy of cData.cTimelapse.cellsToPlot.
                        Cell labels initially allocated when cells are
                        selected. Only cells in this original will have
                        data extracted. Position corresponds to the label
                        of these cells.
                        Tracks the labels of cells which should be
                        plotted. 1's in the matrix denote a cell which
                        is being tracked, while the row number gives its
                        label.
                        cellsToPlot is edited to track which cells are
                        currently selected in the GUI.
    
                      trackingColors
                        Tracks the RGB color of individual cells in the
                        GUI. As with the previous, the row of a value
                        denotes the cell to which is applies, and the
                        three columns denote the RGB value in double
                        format.
    
                      cellsWithData
                        Lists the cell labels which had data extracted
                        from them. Used to make sure that a cell with no
                        data cannot be selected (because that would crash
                        the thing)

                    upslopes/downslopes
                        Matrices same size as extracted data. Saved data where
                        there is an upslope or downslope in the track data
    
      SYNTAX:         displayCellAsicData(timelapseTrapsGUI)
                      displayCellAsicData(timelapseTrapsGUI, cellsTotrack)
              
                        cellsToTrack is an optional argument, which specifies an
                        alternate cData.cellsToTrack matrix (usually blank
                        to give no initial tracks). Including cells which
                        don't have data will cause a crash(again), so take care.
                                                                           
    
