classdef DistNormal < handle & GKConvolvable
    %DIST_NORMAL Gaussian distribution object for kernel EP framework.
    
    properties (SetAccess=private)
        mean
        % precision matrix
        precision
        
        variance=[];
    end
    
    properties (SetAccess=private, GetAccess=private)
        Z % normalization constant
    end
    methods
        %constructor
        function this = DistNormal(m, var)
            assert(~isempty(m));
            assert(~isempty(var));
            this.mean = m(:);
            assert(all(size(var)==size(var'))) %square
            this.variance = var;
        end
        
        function m = get.mean(this)
            m = this.mean;
        end
        
        function prec = get.precision(this)
            if isempty(this.precision)
                % expensive. Try to find a way for lazy evaluation later.
                reg = (abs(this.variance) < 1e-5)*1e-5;
                this.precision = inv(this.variance + reg);
            end
            prec = this.precision;
        end
        
        function var = get.variance(this)
            var = this.variance;
        end
        
        function X = draw(this, N)
            % return dxN sample from the distribution
            X = mvnrnd(this.mean', this.variance, N)';
            
        end
        
        function Mux = conv_gaussian(this, X, gw)
            % X (dxn)
            % gw= a scalar for Gaussian kernel parameter
            % convolve this distribution (i.e., a message) with a Gaussian
            % kernel on sample in X. This is equivalent to an expectation of
            % the Gaussian kernel with respect to this distribution
            % (message m): E_{m(Y)}[k(x_i, Y] where x_i is in X
            [d,n] = size(X);
            assert(d==length(this.mean));
            
%             we can do better. sqrt(det(2*pi*Sigma)) will cancel anyway.
            Mux = sqrt(det(2*pi*Sigma))*mvnpdf(X', this.mean(:)', this.variance+gw*eye(d) );
            
        end
        
        function D=density(this, X)
            
            % Variance can be negative in EP. mvnpdf does not accept it.
            %             D = mvnpdf(X', this.mean(:)', this.variance + 1e-6*eye(d) )';
            
            % Naive implementation. Can do better with det(.) ?
            P = this.precision;
            PX = P*X;
            mu = this.mean;
            I = 0.5*( sum(X.*PX, 1) + mu'*P*mu - 2*mu'*PX );
            D = this.Z*exp(-I);
        end
        
        function f=func(this)
            % return a function handle for density. Useful for plotting
            f = @(x)mvnpdf(x, this.mean, this.variance);
        end
        
        function z = get.Z(this)
            if isempty(this.Z)
                d = length(this.mean);
                this.Z = ((2*pi)^(-d/2))*(det(this.variance)^(-1/2));
            end
            z = this.Z;
        end
        function D = mtimes(this, distNorm)
            if ~isa(distNorm, 'DistNormal')
                error('mtimes only works with DistNormal obj.');
            end
            m1 = this.mean;
            p1 = this.precision;
            m2 = distNorm.mean;
            p2 = distNorm.precision;
            
            prec = p1+p2;
            nmean = prec \ (p1*m1 + p2*m2);
            D = DistNormal(nmean, prec);
        end
        
        function D = mrdivide(this, distNorm)
            if ~isa(distNorm, 'DistNormal')
                error('mrdivide only works with DistNormal obj.');
            end
            m1 = this.mean;
            p1 = this.precision;
            m2 = distNorm.mean;
            p2 = distNorm.precision;
            
            prec = p1-p2;
            nmean = prec \ (p1*m1 - p2*m2);
            D = DistNormal(nmean, prec);
        end
        
    end %end methods
    
    
    methods (Static)
        
        function S=normalSuffStat(X)
            % phi(x)=[x, x^2]' or phi(x)=[x; vec(xx')]
            % X (dxn)
            [d,n] = size(X);
            %             S = zeros(d+d^2, n);
            %             very slow
            %             for i=1:n
            %                 Xi = X(:, i);
            %                 S(:, i) = [Xi; reshape(Xi*Xi', d^2, 1)];
            %             end
            %assume 1d for now
            S = [X; X.^2];
            
        end
    end
end
