classdef DriverMode < Simulink.IntEnumType
  enumeration
    Comfort(0)
    SportPlus(1)
  end
   methods (Static)
    function retVal = getDefaultValue()
      retVal = DriverMode.Comfort;
    end
    function retVal = getHeaderFile()
         retVal = 'impl_type_drivermode.h';
    end
  end
end