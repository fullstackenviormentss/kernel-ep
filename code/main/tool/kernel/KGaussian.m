classdef KGaussian < Kernel
    %KGAUSSIAN Gaussian kernel
    % exp(\| x-y \|_2^2 / (2^sigma2))
    
    properties (SetAccess=private)
        % sigma squared
        sigma2;
    end
    
    methods
        
        function this=KGaussian(sigma2)
            assert(isnumeric(sigma2));
            if length(sigma2) == 1
                this.sigma2 = sigma2;
            else
                for i=1:length(sigma2)
                    this(i) = sigma2(i);
                end
            end
        end
        
        function Kmat = eval(this, X, Y)
            % X, Y are data matrices where each column is one instance
            assert(isnumeric(X));
            assert(isnumeric(Y));
            Kmat = kerGaussian(X, Y, this.sigma2);
            
        end
        
        function Kvec = pairEval(this, X, Y)
            % lazy implmentation. Obviously this can be improved.
            assert(isnumeric(X));
            assert(isnumeric(Y));
            n1=size(X, 2);
            n2=size(Y, 2);
            assert(n1==n2);
            Kvec = zeros(1, n1);
            for i=1:n1
                Kvec(i) = this.eval(X(:, i), Y(:, i));
            end
            
        end
        
        function Param = getParam(this)
            Param = {this.sigma2};
        end
        
        function s=shortSummary(this)
            s = sprintf('KGaussian(%.3g)', this.sigma2);
        end
    end
    
    methods (Static)
        function Ks=candidates(params)
            % params is a numeric array
            Kgauss = KGaussian(params);
            Ks = num2cell(Kgauss);
            
        end
    end
    
    
end
