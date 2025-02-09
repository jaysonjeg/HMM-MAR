function L = obslike_ness(ness,Gamma,residuals,XX,k)
%
% Evaluate likelihood of data given observation model
% for chain k, for one continuous trial
% (It's pretty much the same than obslike but simplified)
%
% INPUT
% X          N by ndim data matrix
% ness        NESS data structure
% residuals  in case we train on residuals, the value of those.
% XX        alternatively to X (which in this case can be specified as []),
%               XX can be provided as computed by setxx.m
% OUTPUT
% B          Likelihood of N data points
%
% Author: Diego Vidaurre, OHBA, University of Oxford

K = ness.K;

[T,ndim] = size(residuals);
S = ness.train.S==1;
regressed = sum(S,1)>0;
ltpi = sum(regressed)/2 * log(2*pi);
L = zeros(T+ness.train.maxorder,2);

ldetWishB = 0;
PsiWish_alphasum = 0;
for n = 1:ndim % only diagonal? 
    if ~regressed(n), continue; end
    ldetWishB = ldetWishB+0.5*log(ness.Omega.Gam_rate(n));
    PsiWish_alphasum = PsiWish_alphasum+0.5*psi(ness.Omega.Gam_shape);
end
C = ness.Omega.Gam_shape ./ ness.Omega.Gam_rate;

setstateoptions;

for l = 1:2
        
    if l == 1, Gamma(:,k) = 1; 
    else, Gamma(:,k) = 0; 
    end

    [meand,X] = computeStateResponses(XX,ness,Gamma,1);
    d = residuals(:,regressed) - meand;
    Cd = bsxfun(@times,C(regressed),d)';
    dist = zeros(T,1);
    for n = 1:sum(regressed)
        dist = dist - 0.5 * (d(:,n).*Cd(n,:)');
    end
    
    NormWishtrace = zeros(T,1);
    for n = 1:ndim
        if ~regressed(n), continue; end
        Sind_all = [];
        for k2 = 1:K
            Sind_all = [Sind_all; Sind(:,n)];
        end
        Sind_all = Sind_all == 1;
        if ndim==1
            NormWishtrace = NormWishtrace + 0.5 * C(n) * ...
                sum( (X(:,Sind_all) * ness.state_shared(n).S_W(Sind_all,Sind_all)) ...
                .* X(:,Sind_all), 2);
        else
            NormWishtrace = NormWishtrace + 0.5 * C(n) * ...
                sum( (X(:,Sind_all) * ...
                ness.state_shared(n).S_W(Sind_all,Sind_all)) ...
                .* X(:,Sind_all), 2);
        end
    end
    
    L(ness.train.maxorder+1:end,l) = - ltpi - ldetWishB + ...
        PsiWish_alphasum + dist - NormWishtrace;

end

% if any(all(L<0,2))
%     L(all(L<0,2),:) = L(all(L<0,2),:) - repmat(max(L(all(L<0,2),:),[],2),1,2);
% end
L = exp(L);

end

