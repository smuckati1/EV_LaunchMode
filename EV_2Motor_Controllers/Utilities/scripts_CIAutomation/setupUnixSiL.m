function setupUnixSiL()
% Setup SIL to pass in Linux Environments, by updating the model config
% files to specify the right ProdHWDeviceType
% Assumes default setup is for Windows Environments

bdclose all
Simulink.data.dictionary.closeAll
    

if isunix
    % Specify Unix Env Setup, asusmes you run on Intel x86
    HWsetup = 'Intel->x86-64 (Linux 64)';

    % Open DD containing codegen model configs
    dd = Simulink.data.dictionary.open('dcmtr_ctrl.sldd');
    configs = getSection(dd,'Configurations');
    entry = getEntry(configs,'mtrCtrl_config');
    cs = getValue(entry);

    % Make and save changes for device compilation settings
    set_param(cs,'ProdHWDeviceType',HWsetup);
    disp(['LongBitsAllowed = ' num2str(get_param(cs,'ProdBitPerLong'))])
    setValue(entry,cs)
    saveChanges(dd)
    dd.close
end
