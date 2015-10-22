function svmmodel = liblinear_train_multicore ( labels, feat, settings )
%
% BRIEF
%   A simple wrapper to provide training of 1-vs-all-classification for LIBLINEAR. No
%   further settings are adjustable currently.
% 
% INPUT
%  labels   -- multi-class labels (#sample x 1)
%  feat     -- features for training images (#samples x # dimensions)
%  settings -- struct for configuring the svm model training, e.g., via
%              'b_verbose', 'f_svm_C', ...
% 
% OUTPUT:
%  svmmodel -- cell ( #classes x 1 ), every model entry is obtained via
%              svmtrain of the corresponding 1-vs-all-problem
%
% date: 30-04-2014 ( dd-mm-yyyy )
% author: Alexander Freytag

    if ( nargin < 3 ) 
        settings = [];
    end
    
    
    libsvm_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        libsvm_options = sprintf('%s -q', libsvm_options);
    end
    
    % cost parameter
    f_svm_C = getFieldWithDefault ( settings, 'f_svm_C', 1);
    libsvm_options = sprintf('%s -c %f', libsvm_options, f_svm_C);    
    
    % do we want to use an offset for the hyperplane?
    if ( getFieldWithDefault ( settings, 'b_addOffset', false) )
        libsvm_options = sprintf('%s -B 1', libsvm_options);    
    end
    
    % which solver to use
    % copied from the liblinear manual:
%       for multi-class classification
%          0 -- L2-regularized logistic regression (primal)
%          2 -- L2-regularized L2-loss support vector classification (primal)
%          11 -- l2-loss SVR
    i_svmSolver = getFieldWithDefault ( settings, 'i_svmSolver', 2);
    i_numThreads = getFieldWithDefault ( settings, 'i_numThreads', 2);
    libsvm_options = sprintf('%s -s %d -n %d', libsvm_options, i_svmSolver, i_numThreads);    

    
    % increase penalty for positive samples according to invers ratio of
    % their number, i.e., if 1/3 is ratio of positive to negative samples, then
    % impact of positives is 3 the times of negatives
    % 
    b_weightBalancing = getFieldWithDefault ( settings, 'b_weightBalancing', false);
    
    
  
    uniqueLabels = unique ( labels );
    i_numClasses = size ( uniqueLabels,1);
    
	
    %# train one-against-all models
    
    if ( ~b_weightBalancing)    
        svmmodel = train( labels, feat, libsvm_options );
    else
        svmmodel = cell( i_numClasses,1);
        for k=1:i_numClasses
            yBin        = 2*double( labels == uniqueLabels( k ) )-1;
            
            fraction = double(sum(yBin==1))/double(numel(yBin));
            libsvm_optionsLocal = sprintf('%s -w1 %f', libsvm_options, 1.0/fraction);
            svmmodel{ k } = train( yBin, feat, libsvm_optionsLocal );
            
            %store the unique class label for later evaluations.
            svmmodel{ k }.uniqueLabel = uniqueLabels( k );
        end         
    end
    
end
