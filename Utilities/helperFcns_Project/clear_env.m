function clear_env()

% disp('Closing all desktop editors matlab.desktop.editor.getAll .... ')
% closeNoPrompt(matlab.desktop.editor.getAll);
% disp('Closing all desktop editors matlab.desktop.editor.getAll .... DONE!')


disp('Closing Simulink Test Manager .... ')
sltest.testmanager.clearResults
sltest.testmanager.close
disp('Closing Simulink Test Manager .... DONE')

disp('Closing Simulink Library Browser .... ')
slLibraryBrowser
slLibraryBrowser('close')   % Close Simulink Library Browser
disp('Closing Simulink Library Browser .... DONE')

disp('Closing Simulink Data Dictionaries .... ')
Simulink.data.dictionary.closeAll('-discard')
disp('Closing Simulink Data Dictionaries .... DONE')

disp('Going back to project root folder .... ')
proj = currentProject;
cd(proj.RootFolder)

clear proj
disp('Going back to project root folder .... DONE')

% Clear up MATLAB to start the next run
disp('Close all figures .... ')
close all                   % Close figures
disp('Close all figures .... DONE')
disp('Close all Block Diagrams (Simulink models) .... ')
bdclose all                 % Close models
disp('Close all Block Diagrams (Simulink models) .... DONE')
disp('Close/Clear classes base using evalin(base,clear) .... ')
evalin('base','clear')      % Clean up workspace
disp('Close/Clear classes base using evalin(base,clear) .... DONE')

clc                         % Clean up command window


