function scrubSharedUtils()
% Clear shared utils from previous builds for clean Codegen/SiL
    prj = currentProject;
    fldrname = fullfile(prj.SimulinkCodeGenFolder,'slprj','ert','_sharedutils');
    if isfolder(fldrname)
        rmdir(fldrname,'s')
    end 
    fldrname = fullfile(prj.SimulinkCacheFolder,'slprj','sim','_sharedutils');
    if isfolder(fldrname)
        rmdir(fldrname,'s')
    end 
    fldrname = fullfile(prj.SimulinkCodeGenFolder,'slprj','autosar','_sharedutils');
    if isfolder(fldrname)
        rmdir(fldrname,'s')
    end 