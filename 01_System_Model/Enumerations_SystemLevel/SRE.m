classdef SRE < Simulink.IntEnumType
  enumeration
    Standby(0)
    Charging(1)
    Driving(2)
    SportMode(3)
  end
   methods (Static)
    function retVal = getDefaultValue()
      retVal = SRE.Standby;
    end
    function retVal = getHeaderFile()

        ECUname = gcs;
        parentName = get_param(gcs,'Parent');
        while ~isempty(parentName)
            ECUname = parentName;
            parentName = get_param(parentName,'Parent');
        end
        ECUtype = get_param(ECUname,'SystemTargetFile');
        if strcmp(ECUtype,'autosar.tlc')
            retVal = 'Rte_Type.h';
        else
            retVal = 'impl_type_sre.h';
        end
        
    end
  end
end