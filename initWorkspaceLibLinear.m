function initWorkspaceLibLinear
% function initWorkspaceLibLinear
% 
% BRIEF
%   Add local subfolders and 3rd party libraries to Matlabs work space.
%
%   Exemplary call from external position:
%        LIBLINEARWRAPDIR = '/place/to/this/repository/';
%        currentDir = pwd;
%        cd ( LIBLINEARWRAPDIR );
%        initWorkspaceLibLinear;
%        cd ( currentDir );
%    
% 
% Author: Alexander Freytag

    %% setup paths in user-specific manner


    % currently we do not have any dependencies, but if we would have some,
    % we would add them here  
    
    %% add paths which come with this repository
    
    if strcmp( getenv('USER'), 'freytag')
        LIBLINEARDIR    = '/home/freytag/code/3rdParty/liblinear-1.93/matlab/';   
    elseif strcmp( getenv('USER'), 'rodner')
        LIBLINEARDIR    = '/home/freytag/code/3rdParty/liblinear-1.93/matlab/';
    elseif strcmp( getenv('USER'), 'kaeding')
        LIBLINEARDIR    = '/home/kaeding/lib/liblinear-multicore-2.1-2/matlab/';   
    else
        fprintf('Unknown user %s and unknown default settings', getenv('USER') ); 
    end    
    
    % add main path
    b_recursive             = false; 
    b_overwrite             = true;
    s_pathMain              = fullfile(pwd);
    addPathSafely ( s_pathMain, b_recursive, b_overwrite )
    clear ( 's_pathMain' );    
    
    % for addFieldWithDefault.m
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathMisc              = fullfile(pwd, 'misc');
    addPathSafely ( s_pathMisc, b_recursive, b_overwrite )
    clear ( 's_pathMisc' );      

    % for binary evaluation metrics such as auc during cross val
    b_recursive             = true; 
    b_overwrite             = true;
    s_pathMisc              = fullfile(pwd, 'binary');
    addPathSafely ( s_pathMisc, b_recursive, b_overwrite )
    clear ( 's_pathMisc' );     
        
    %% 3rd party, untouched
    
    if ( isempty(LIBLINEARDIR) )
        fprintf('InitPatchDiscovery-WARNING - no LIBLINEARDIR dir found on your machine. Code is available at http://www.csie.ntu.edu.tw/~cjlin/liblinear/ \n');
    else
        b_recursive         = true; 
        b_overwrite         = true;
        addPathSafely ( LIBLINEARDIR, b_recursive, b_overwrite );        
    end 
    
    %% clean up
    
    clear( 'LIBLINEARDIR' );
end


function addPathSafely ( s_path, b_recursive, b_overwrite )
    if ( ~isempty(strfind(path, [s_path , pathsep])) )
        if ( b_overwrite )
            if ( b_recursive )
                rmpath( genpath( s_path ) );
            else
                rmpath( s_path );
            end
        else
            fprintf('initWSLibLinear - %s already in your path but overwriting de-activated.\n', s_path);
            return;
        end
    end
    
    if ( b_recursive )
        addpath( genpath( s_path ) );
    else
        addpath( s_path );
    end
end
