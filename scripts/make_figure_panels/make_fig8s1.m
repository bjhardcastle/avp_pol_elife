% Generate plots for Fig8s6 (E-PG responses in protocerebral bridge)
% Each cell can be run independently

pathsAVP
thisfigpath = fig8s1path;
if exist(thisfigpath,'dir')
    try rmdir(thisfigpath,'s'),end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% All panels using single cycle responses 
printpath = fig8s1path;
plot_PB_single_cycle

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Glomerulus pairing scheme
loadSS00096_PB
printpath = fig8s1path;

plot_PB_glom_pairing_crosscorr
prefix = 'glom_pairing_crosscorr';
savename = '';
suffix = '';
printAVP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Autocorrelation peak shift from stimulus period
pathsAVP
printpath = fig8s1path;
plot_R4m_EPG_autocorr_peak_timeshift

prefix = 'autocorr_peak_timeshift';
savename = 'R4m_EPG';
suffix = '';
printAVP

