%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Copyright Weifeng Liu 
%CNEL
%July 1, 2008
%
%description:
%compare the performance of KLMS and KRLS in channel
%equalization
%Abrupt change and reconvergence
%
%Usage:
%ch4, channel equalization
%
%Outside functions called or toolboxes used:
%LMS1s, APA1s, sparseKLMS1s, sparseKAPA1s, sparseKAPA2s
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear all,
close all
clc

%======filter config=======
%time delay (embedding) length
inputDimension = 3;
equalizationDelay = 0;
%Kernel parameters
typeKernel = 'Gauss';
paramKernel = .1;

%======end of config=======
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%       Parameters
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



flagLearningCurve = 1;

toleranceDistance = 0.05;
tolerancePredictError = 0.01;

stepSizeKlms1 = .15;
stepSizeWeightKlms1 = 0;
stepSizeBiasKlms1 = 0;

regularizationFactorKrls = 0.1;
forgettingFactorKrls = 1;
thKrls = -1.04;    
    
%data size
trainSize = 1500;
testSize = 100;

change_time = 500;
noise_std = 0.1;


%======end of data===========
%%    
MC = 50;
learningCurveKlms1_en = zeros(trainSize,1);
netSizeKlms1_en = zeros(trainSize,1);
ensembleLearningCurveKrls = zeros(trainSize,1);
ensembleNetSizeKrls = zeros(trainSize,1);

disp([num2str(MC), '  Monte Carlo simulations. Please wait...'])
for mc = 1:MC
    disp(mc)
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%
	%       Data Formatting
	%
	%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	%=========data===============
	% Generate binary data
	u = sign(randn(1,trainSize*1.5));
	z = filter([1 0.5],1,u);
	% Channel noise
	ns = noise_std*randn(1,length(z));
	% Ouput of the nonlinear channel
	y = z - 0.9*z.^2 + ns;
    y(change_time:end) = 0.9*z(change_time:end).^2 - z(change_time:end) + ns(change_time:end);

	%data embedding
	trainInput = zeros(inputDimension,trainSize);
	for k=1:trainSize
		trainInput(:,k) = y(k:k+inputDimension-1)';
	end
	% Desired signal
	trainTarget = zeros(trainSize,1);
	for ii=1:trainSize
		trainTarget(ii) = u(equalizationDelay+ii);
	end % Generate binary data
    %======end of data===========

    %=========sparse Kernel LMS 1===================

    [expansionCoefficientKlms1,weightVectorKlms1,biasTermKlms1,learningCurveKlms1,dictionaryIndexKlms1,netSizeKlms1] = ...
        sparseKLMS1s(trainInput,trainTarget,typeKernel,paramKernel,...
        stepSizeKlms1,stepSizeWeightKlms1,stepSizeBiasKlms1,toleranceDistance,tolerancePredictError,flagLearningCurve);
    
    learningCurveKlms1_en = learningCurveKlms1_en + learningCurveKlms1;
    netSizeKlms1_en = netSizeKlms1_en + netSizeKlms1;
    %=========end of sparse Kernel LMS================
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %
    %              KRLS
    %
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    [expansionCoefficientKrls,dictionaryIndexKrls, learningCurveKrls, netSizeKrls, CI] = ...
        KRLS_ALDs(trainInput,trainTarget,typeKernel,paramKernel,regularizationFactorKrls,forgettingFactorKrls, thKrls);
                    
    ensembleLearningCurveKrls = ensembleLearningCurveKrls + learningCurveKrls;
    ensembleNetSizeKrls = ensembleNetSizeKrls + netSizeKrls;
    % =========end of KRLS================
    
    %%
end%mc

%%
lineWid = 3;
if flagLearningCurve
	figure,
	plot(learningCurveKlms1_en/MC,'b-','LineWidth', lineWid)
    hold on
	plot(ensembleLearningCurveKrls/MC,'r-.','LineWidth', lineWid)
	hold off
	legend('KLMS-NC','KRLS-ALD')
    set(gca, 'FontSize', 14);
    set(gca, 'FontName', 'Arial');
    xlabel('iteration'),ylabel('MSE')
    grid on
end

figure,
plot(netSizeKlms1_en/MC,'b-','LineWidth', lineWid)
hold on
plot(ensembleNetSizeKrls/MC,'r--','LineWidth', lineWid)
hold off
legend('KLMS-NC','KRLS-ALD')
set(gca, 'FontSize', 14);
set(gca, 'FontName', 'Arial');
xlabel('iteration'),ylabel('network size')
grid on
