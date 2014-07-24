classdef KEGaussian < Kernel
    %KEGAUSSIAN Kernel for distributions defined as the inner product of
    %their mean embeddings into Gaussian RKHS.
    %
    % Expected product Gaussian kernel for mean embeddings of Gaussian
    % distributions. Equivalently, compute the inner product of mean embedding
    % using Gaussian kernel.
    %
    % Return K which is a n1 x n2 matrix where K_ij represents the inner
    % product of the mean embeddings of Gaussians in the RKHS induced by the
    % Gaussian kernel with width sigma2. Since the mapped distributions and the
    % kernel are Gaussian, the kernel evaluation can be computed analytically.
    %
    % If non-DistNormal Distribution is specified, mean/variance will be extracted
    % and treated as being a DistNormal (moment-matching approximation).
    %
    
    properties (SetAccess=private)
        % Gaussian width^2 for each dimension 
        gwidth2s;
    end
    
    methods
        function this=KEGaussian(gwidth2s)
            % sigma2 = Gaussian width^2 used for embedding into Gaussian
            % RKHS
            assert(all(gwidth2s>0), 'Gaussian width must be > 0');
            this.gwidth2s=gwidth2s;
        end
        
        
        function Kmat = eval(this, D1, D2)
            assert(isa(D1, 'Distribution') || isa(D1, 'DistArray'));
            assert(isa(D2, 'Distribution') || isa(D2, 'DistArray'));
            d1=unique([ D1.d ]);
            d2=unique([ D2.d ]);
            assert(isscalar(d1));
            assert(isscalar(d2));
            assert(d1==d2, 'Dimension of two Distributions must match');
            assert(d1==length(this.gwidth2s), 'length(gwidth2s) does not match dimension of Distribution');
            M1 = [D1.mean];
            M2 = [D2.mean];
            d=d1;
            if d==1
                assert(isscalar(this.gwidth2s));
                sigma2=this.gwidth2s;
                V2 = [D2.variance];
                V1 = [D1.variance];
                % width matrix
                W = sigma2 + bsxfun(@plus, V1', V2);

                D = bsxfun(@minus, M1', M2).^2;
                % normalizer matrix
                Z = sqrt(sigma2./W);
                % assert(all(imag(Z(:))==0));
                % ### hack to prevent negative W in case V1, V2 contain negative variances
                if any(imag(Z)>0)
                    warning('In %s, kernel matrix contains imaginary entries.', mfilename);
                end
                Z(imag(Z)~=0) = 0;
                Kmat = Z.*exp(-D./(2*W) );
            else
                % multivariate case 
                % The following is an adhoc implementation which needs to be improved.
                %
                n1=length(D1);
                n2=length(D2);
                Kmat=zeros(n1, n2);
                % do by columns
                Sigma=diag(this.gwidth2s);
                detSigmaInv=1/det(Sigma);
                for j=1:n2
                    dj=D2(j);
                    DetD=zeros(n1, 1);
                    MStack=bsxfun(@minus, [D1.mean], dj.mean)';
                    MD=zeros(n1, d);
                    for i=1:n1
                        di=D1(i);
                        Eij= (di.variance+dj.variance+Sigma);
                        DetD(i)=1/det(Eij);
                        MD(i, :)=MStack(i, :)/Eij;
                    end
                    % column of multipliers
                    Z=sqrt(DetD/detSigmaInv);
                    Kmat(:, j)=Z.*exp(-0.5* sum( MD.*MStack, 2) );
                end
            end

        end


        function Kvec = pairEval(this, D1, D2)
            assert(isa(D1, 'Distribution') || isa(D1, 'DistArray'));
            assert(isa(D2, 'Distribution') || isa(D2, 'DistArray'));
            assert(length(D1)==length(D2));
            n = length(D1);
            if D1(1).d==1
                assert(isscalar(this.gwidth2s));
                sig2 = this.gwidth2s;

                M1=[D1.mean];
                M2=[D2.mean];
                V1=[D1.variance];
                V2=[D2.variance];

                W = sig2 + V1+V2;
                D2 = (M1-M2).^2;
                E = exp(-D2./(2*W));
                % normalizer
                Z = sqrt(sig2./W);
                % ### hack to prevent negative W in case V1, V2 contain negative variances
                if any(imag(Z)>0)
                    warning('In %s, kernel matrix contains imaginary entries.', mfilename);
                end
                Z(imag(Z)~=0) = 0;
                Kvec = Z.*E;
            else
                % multivariate case 
                % The following is an adhoc implementation which needs to be improved.
                %
                Sigma=diag(this.gwidth2s);
                detSigmaInv=1/det(Sigma);
                Invs=cell(1, n);
                DetD=zeros(1, n);
                for i=1:n
                    d1=D1(i);
                    d2=D2(i);
                    % inv not a good idea ?
                    Di=inv(d1.variance+d2.variance+Sigma);
                    Invs{i}=Di;
                    DetD(i)=det(Di);
                end
                InvStack=vertcat(Invs{:});
                MStack=bsxfun(@minus, [D1.mean], [D2.mean])';
                % column of multipliers
                Z=sqrt(DetD/detSigmaInv);
                Kvec=Z.*exp(-0.5* sum( (MStack*InvStack).*MStack, 2) )';
            end
        end

        function Param = getParam(this)
            Param = {this.gwidth2s};
        end

        function s=shortSummary(this)
            s = sprintf('%s([%s])', mfilename, num2str(this.gwidth2s) );
        end
    end

end

