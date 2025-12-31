classdef GenCodeandPackIt < padv.builtin.task.GenerateCode
    % task definition goes here
    methods

        function obj = GenCodeandPackIt(options)
            arguments
                options.Name = "Gen and package Code & Codegen Opts";
                options.Title = "GenCodeandPackIt";
            end
            obj@padv.builtin.task.GenerateCode(Name = options.Name);
            obj.Title = options.Title;
        end
    end
    methods (Access = protected)
      function step1(obj)
         % Subclass version
      end
    end

end