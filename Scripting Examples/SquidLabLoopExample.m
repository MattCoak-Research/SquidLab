% Datafiles to import.
dataFilePath = "SquidLab/Example Data/MvT RawData.rw.dat";
backgroundFilePath = "SquidLab/Example Data/MvT Background.rw.dat";

actions = squidlab.Actions;
plotter = squidlab.scanset.ScanPlotter();   %Not actually used in this example

% Do data import.
importerName = "squidlab.import.MPMS3";
scaleFactor = 1;

% The import is probably quite slow.
rawData = actions.importData(dataFilePath, importerName, scaleFactor);
rawBackground = actions.importData(backgroundFilePath, importerName, scaleFactor);

ppData = actions.postProcess(rawData, 'AverageConsecutive', true, 'SmoothingSpan', 11);
ppBackground = actions.postProcess(rawBackground, 'AverageConsecutive', true, 'SmoothingSpan', 11);
disp("Starting shift");

%Make a new figure to plot data in
figure;

for zShift = -2 : 0.4 : 2
    %Print the value we are working on to the console, as a simple progress bar
    disp(zShift);

    %Shift the data in z
    ppDataShifted = actions.postProcess(ppData, 'ShiftZ', zShift);

    %Subtract background
    backsubScanSets = actions.subtractBackground(ppDataShifted, ppBackground);

    %Plot only the first point (base temperature by default) of the scan
    backsubScanSet.UseScanRange(1,1);

    %Plot the data in backsubScanSet. (:,1) means all data points in the
    %first column - z values, (:,2) means all voltage values. Scanset data
    %is stored in a 3 dimensional array, with the 3rd index the scan number
    %(ie the temperature). These could also be (:,1,1) and (:,2,1) but we
    %did UseScanRange above to make it easier.
    %Note that plotting can also be done using the Squidlab Plotter object,
    %nicer and more similar in presentation to the GUI, but with less
    %flexibility
    plot(backsubScanSet.SelectedScans(:,1), backsubScanSet.SelectedScans(:,2), "DisplayName", num2str(zShift) + " mm shift");
    
    %Tell MATLAB not to overwrite the current plot, but overplot an additional one on the same axes 
    hold on;
end

%Add axis labels and legend
xlabel("z (mm)");
ylabel("Raw Voltage (V)");
legend;
hold off;
disp("Done");
