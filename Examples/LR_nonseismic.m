% clear all; % sasha intifact
RandStream.setDefaultStream(RandStream('mt19937ar','seed',1));
addpath(genpath('C:\Users\mona\Dropbox\Research\Low-Rank\Matrix_Pareto_Factorization\SLIM.Projects.MatrixParetoFact\scripts\Exp_Proxy_versus_true_nuclear_norm\spgl1Latest'));
addpath(genpath('/users/slic/rkumar/Self_Function'));
%% Generate rank 20 matrix
sigmas = [1e2*rand(20,1); zeros((100-20), 1)];
% set up U and V
U = randn(100, 20);
[Q R] = qr(U);
U = Q;
V = randn(100,20);
[Q R] = qr(V);
V = Q;
% Form A
D = U*diag(sigmas)*V';  
N   = 100;       % the matrix is N x N
r   = 20;
df  = 2*N*r - r^2;  % degrees of freedom of a N x N rank r matrix
nSamples    = floor(1.5*df); % number of observed entries
rPerm   = randperm(N^2); % use "randsample" if you have the stats toolbox
omega   = transp(sort( rPerm(1:nSamples) ));
b = zeros(N);
b(omega)=D(omega);
b = vec(b);
%% SPGL1 
params.afunT = @(x)reshape(x,N,N);
params.Ind = find(b==0);
params.afun = @(x)afun(x,params.Ind);
params.numr = N;
params.numc = N;
params.funForward = @NLfunForward;
opts = spgSetParms('optTol',1e-4, ...
                   'bpTol', 1e-6,...
                   'decTol',1e-6,...
                   'project', @TraceNorm_project, ...
                   'primal_norm', @TraceNorm_primal, ...
                   'dual_norm', @TraceNorm_dual, ...
                   'proxy', 1, ...
                   'ignorePErr', 1, ...
                   'weights', []);
               
epsilon = [1e-1 1e-2 1e-3 1e-4];
rank = 20;
opts.funPenalty = @funLS;
sigma = opts.funPenalty(b); %norm(b,2);

%%
for i= 1:length(rank)
    params.nr = rank(i);
    LInit   = randn(params.numr,params.nr);
    RInit   = randn(params.numc,params.nr);
    xinit   = 1e-3*[vec(LInit);vec(RInit)];
    tau     = norm(xinit,1);
    for j = 1:length(epsilon)
        sigmafact = epsilon(j)*sigma;
        tstart = tic;
        [xLSA,r,g,info] = spgl1(@NLfunForward,b,tau,sigmafact,xinit,opts,params);
        time(i,j) = toc(tstart);
        e = params.numr*params.nr;
        L1 = xLSA(1:e);
        R1 = xLSA(e+1:end);
        L1 = reshape(L1,params.numr,params.nr);
        R1 = reshape(R1,params.numc,params.nr);
        xlsa = L1*R1';
        SNR(i,j) = -20*log10(norm(D-xlsa,'fro')/norm(D,'fro'));
    end
    
end

save('LR_nonseismic_40.mat','SNR','time');

SNR
time
