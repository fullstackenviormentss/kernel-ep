classdef Distribution < handle & Density
    %DIST A semantic tag for distributions.
    
    properties (Abstract, SetAccess=protected)
        mean;
        variance;
        
        % A cell array of parameters in the usual parametrization. For
        % Gaussian for example, this should be {mean, variance}.
        parameters;

        % dimension of the domain. For example, 1 for beta distribution.
        d;
    end
    
    methods (Abstract)
        % Return true if this is a proper distribution e.g., positive
        % variance, not having inf mean, etc.
        p=isProper(this);
        
        % Return the names in cell array corresponding to this.parameters
        % The cell array must have the same length as this.parameters.
        names=getParamNames(this);

        % Return the underlying Distribution type e.g., DistNormal
        t=getDistType(this);

    end
    
    methods (Static)
        function builder = getDistBuilder()
            builder=[];
            error('Subclass of Distribution needs to override this.');
            
        end
    end
    
end

