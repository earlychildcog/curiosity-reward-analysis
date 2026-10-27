# curR: exploration task ET analysis, visits 1, 2, 3

Find the latest version on https://github.com/earlychildcog/curiosity-reward-analysis/


To replicate the findings of the paper 'Infants trade off reward for information:
longitudinal evidence for curiosity-driven information-seeking in the second year of life':


First run the prop recessing and analysis scripts:

1: curR_ET_1_preprocess.m

    for visit = 1; visit = 2, and finally visit = 3
     (change the value in the script and re-run)
    
    
2: curR_ET_2_analysis.m

    for visit = 1; visit = 2, and finally visit = 3 while minTimeOnTopScreen = 1000
     (change the value in the script and re-run)
    for visit = 1, run it once more for minTimeOnTopScreen = 2000
   
3: curR_ET_3_concatenateAllVisitsAndPlot.m

    Run this one once, after both other scripts have been ran for all visits.



/!\ Respect the order of the scripts as they depend on each other.


The scripts output files in multiple folders.

Use the csv files in this folder to conduct the statistical analyses and
check the tables:
    /Users/[yourusername]/Data/curR/All 3 visits/data_allVisits.csv'
JASP files pointing to the csv files outputted are also found in this folder.

The data is sensitive & thus not provided here on GitHub -- please get in 
touch with the authors if you require access to the data. Data sharing 
might not always be possible depending on Danish & EU regulations.



NOTE: some of the scripts can be ran without using parallel processing;
most of the ET scripts require Matlab's parallel processing toolbox and a
computer with at least 6 cores.
