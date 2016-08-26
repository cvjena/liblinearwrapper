function svmmodel = liblinear_train ( labels, feat, settings )
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
% last modified: 22-10-2015
% author: Alexander Freytag, Christoph Käding

    if ( nargin < 3 ) 
        settings = [];
    end
    
    
    liblinear_options = '';
    
    % outputs for training
    if ( ~ getFieldWithDefault ( settings, 'b_verbose', false ) )
        liblinear_options = sprintf('%s -q', liblinear_options);
    end
    
    % cost parameter
    f_svm_C = getFieldWithDefault ( settings, 'f_svm_C', 1);
    liblinear_options = sprintf('%s -c %f', liblinear_options, f_svm_C);    
    
    % do we want to use an offset for the hyperplane?
    if ( getFieldWithDefault ( settings, 'b_addOffset', false) )
        liblinear_options = sprintf('%s -B 1', liblinear_options);    
    end
    
    % add multithreading
    % NOTE: - requires liblinear-multicore
    %       - supports only -s 0, -s 2, or -s 11 (so far)
    i_numThreads = getFieldWithDefault ( settings, 'i_numThreads', 1);
    if i_numThreads > 1
        liblinear_options = sprintf('%s -n %d', liblinear_options, i_numThreads);
    end
        
    % which solver to use
    % copied from the liblinear manual:
%       for multi-class classification
%          0 -- L2-regularized logistic regression (primal)
%          1 -- L2-regularized L2-loss support vector classification (dual)
%          2 -- L2-regularized L2-loss support vector classification (primal)
%          3 -- L2-regularized L1-loss support vector classification (dual)
%          4 -- support vector classification by Crammer and Singer
%          5 -- L1-regularized L2-loss support vector classification
%          6 -- L1-regularized logistic regression
%          7 -- L2-regularized logistic regression (dual)    
    i_svmSolver = getFieldWithDefault ( settings, 'i_svmSolver', 1);
    liblinear_options = sprintf('%s -s %d', liblinear_options, i_svmSolver);    

    
    % increase penalty for positive samples according to invers ratio of
    % their number, i.e., if 1/3 is ratio of positive to negative samples, then
    % impact of positives is 3 the times of negatives
    % 
    b_weightBalancing = getFieldWithDefault ( settings, 'b_weightBalancing', false);
    
    % increase penalty for positive samples according to invers ratio of
    % their number, i.e., if 1/3 is ratio of positive to negative samples, then
    % impact of positives is 3 the times of negatives
    % 
    b_cross_val = getFieldWithDefault ( settings, 'b_cross_val', false);   
    if ( b_cross_val && (length(unique(labels)) ~=2 ) )
        i_num_folds = getFieldWithDefault ( settings, 'i_num_folds', 10);  
        liblinear_options = sprintf('%s -v %d', liblinear_options, i_num_folds ); 
    end
    
    
  
    uniqueLabels = unique ( labels );
    i_numClasses = size ( uniqueLabels,1);
    
	
    %# train one-against-all models
    
    if ( ~b_weightBalancing)    
        if ( b_cross_val && (length(unique(labels)) ==2 ) )
            
            % measure of accuracy during cross validation is auc   
            svmmodel = do_binary_cross_validation( labels, feat, liblinear_options, getFieldWithDefault ( settings, 'i_num_folds', 10) );
        else
            svmmodel = train( labels, feat, liblinear_options );
        end
    else
        svmmodel = cell( i_numClasses,1);
        for k=1:i_numClasses
            yBin        = 2*double( labels == uniqueLabels( k ) )-1;
            
            fraction = double(sum(yBin==1))/double(numel(yBin));
            liblinear_optionsLocal = sprintf('%s -w1 %f', liblinear_options, 1.0/fraction);
            svmmodel{ k } = train( yBin, feat, liblinear_optionsLocal );
            
            %store the unique class label for later evaluations.
            svmmodel{ k }.uniqueLabel = uniqueLabels( k );
        end         
    end
       
end
