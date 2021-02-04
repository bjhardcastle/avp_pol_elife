function superPolAngResultantCirc(objarray,usePSIweighting,usePSIthreshold)
%SUPERPOLANGRESULTANT(objarray,useTuningColors) Simple resultant plot
% modified to not assume axial (bimodal) pol responses / tunings

if nargin <2 || isempty(usePSIweighting)
    usePSIweighting = 0;
end
if nargin <3 || isempty(usePSIthreshold)
    usePSIthreshold = 0;
end

getAVPplotParams
superUseMSP(objarray,1) % Use MSP instead of MIP

% Initialize arrays for storing resultant angles & lengths for each recording
vecDirArray = nan(length(objarray),1);
vecLengthArray = nan(length(objarray),1);
flyArray = nan(length(objarray),1);


for oidx = 1:length(objarray)
    if objarray(oidx).containsPolMapExp>=4 ...
            && ( objarray(oidx).MIP.UseMSP || objarray(oidx).numZPlanes==1 )
        
        % First find the tunings of all masked pixels without pooling 0+180
        % (i.e. not assuming axial/bimodal responses)
        polAngs = objarray(oidx).MIP.expPolAngs(objarray(oidx).containsPolMapExp);
        pixPolResp = objarray(oidx).MIP.polAngResp(objarray(oidx).MIP.layerMask.mask,:);
        pixPolWeight = pixPolResp;
        [~,axtheta] = circ_rangle(circ_axial(deg2rad(repmat(polAngs(1:length(polAngs)),size(pixPolResp,1),1)),2), pixPolWeight, deg2rad(mode(diff(polAngs))), 2);
        theta = axtheta;
        tuningAngs = wrapTo360(rad2deg(theta));

        maskedPolSelFrameVector = getPolSelMaskedVector(objarray(oidx).MIP,'all');
        % all pol ang responses within mask:
        maskedPolTuningFrameVector = tuningAngs;


        if usePSIthreshold
            maskedPolSelFrameVector = maskedPolSelFrameVector(maskedPolSelFrameVector<objarray(oidx).MIP.polSelThreshold);
            maskedPolTuningFrameVector = maskedPolTuningFrameVector( maskedPolSelFrameVector<objarray(oidx).MIP.polSelThreshold);
        end
        
        if sum(~isnan(maskedPolTuningFrameVector)) > 0.01*sum(objarray(oidx).MIP.layerMask.mask) % don't include if only a few pixels respond

            
            % Take the tuning values of all pixels as angles, and their
            % selectivity index as a weight (optional), then find circular mean.
            if usePSIweighting
               weightingVector = maskedPolSelFrameVector; 
            else
               weightingVector = ones(size(maskedPolSelFrameVector)); 
            end
            
            [r,axtheta] = circ_rangle(deg2rad(maskedPolTuningFrameVector), weightingVector, [], 1);
            
            theta = axtheta;

            vecDirArray(oidx) = rad2deg(theta);
            vecLengthArray(oidx) = r;
            flyArray(oidx) = objarray(oidx).Fly;
        
        end
    end
end

% Get number of flies across all returned trials
included_flies = unique(flyArray(~isnan(flyArray)));
populationSize = length(included_flies);

% % Get individual fly mean-traces
% fly_mean_traces = nan(populationSize,size(ctArray,2));
% for ifidx = 1:populationSize
%     fly_mean_traces(ifidx,:) = nanmean( ctArray( (flyArray == included_flies(ifidx)), : ) , 1);
% end
% 
% % Work on these mean-traces to get SEM and the population mean trace
% varTrials = nanstd(fly_mean_traces , [] , 1) ./ sqrt(populationSize);
% meanTrials = nanmean(fly_mean_traces,1);

% to match Weir,Henze 2016, we can adjust angles here or adjust the plot below
% pubVecDirArray = wrapTo180(-vecDirArray-270);
pubVecDirArray = vecDirArray;

% plot 
f = figure('color','w');
ax = polaraxes;
hold(ax,'on')
for pIdx = 1:length(vecLengthArray)
    if ~isnan(vecLengthArray(pIdx))
    rVals = [0 vecLengthArray(pIdx)];
    tVals = [deg2rad(pubVecDirArray(pIdx)) deg2rad(pubVecDirArray(pIdx))];
    
    p(pIdx) = polarplot(tVals,rVals,'color','k','LineWidth',0.5);
    end
end
% adjust angle representation to match Weir,Henze 2016
ax.ThetaDir = 'clockwise';
ax.ThetaZeroLocation = 'left';
ax.ThetaTickLabel = {['  90' char(176)],'','',['  0' char(176)],'','',['-90' char(176)],'','',['180' char(176)],'',''};
ax.ThetaLim = [0 360];
ax.ThetaTick = [0:30:360];

ax.RLim = [0 1];
if max(vecLengthArray) > max(ax.RLim)
    disp('Data may be clipped: reduce RLim(2)')
end
ax.RAxisLocation = 225;
ax.RTick = [0:0.25:max(ax.RLim)];
ax.RTickLabel = {'';'';'';'';'1'};
setAVPaxes(ax,[],defaultAxisHeight_cm)
set(ax,'layer','bottom')

% % % Rayleigh test: h0 is uniform distribution around circle
% % % Since we have axial data we double all the angles before testing
% doubledBinCenters = deg2rad( 2.*(shiftedBinEdges + shiftedBinEdges(1)) );
% ctVec = length(meanTrials).*reshape(fly_mean_traces',[],1); %so that N samples = numFlies*numAngleBins;
% % % alternative using mean values replicated numFlies times:
% %ctVec = length(meanTrials).*repmat(meanTrials,1,size(fly_mean_traces,1))'; %
% angVec = repmat(doubledBinCenters(1:end-1),1,size(fly_mean_traces,1))';
% [pVal] = circ_rtest(angVec,ctVec,deg2rad(2.*binWidth));
% % add to plot for convenience
% text(ax,-80,ax.RLim(2)+0.05,['p=' num2str(pVal)],'FontSize',axisLabelFontSize)

if sum(~isnan(vecLengthArray)) == 1 && oidx == 1
    [r,th] = circ_rangle(deg2rad(maskedPolTuningFrameVector), weightingVector, [], 1);
    t = circ_confmean(deg2rad(maskedPolTuningFrameVector), 0.05, weightingVector, [], 1);
else
    [r,th] = circ_rangle(deg2rad(vecDirArray(~isnan(vecDirArray))), vecLengthArray(~isnan(vecLengthArray)), [], 1);
    t = circ_confmean(deg2rad(vecDirArray(~isnan(vecDirArray))), 0.05, vecLengthArray(~isnan(vecLengthArray)), [], 1);
end

if ~isnan(t)
ciTh = [th-t:0.01:th+t];
ciR = repmat(0.95*ax.RLim(2),1,length(ciTh));
% draw an arc around the mean angle
arcHandle = polarplot(ciTh,ciR,'LineWidth',2,'Color','k');
% keep it at the outside, in case we change the limits
addlistener (ax, 'MarkedClean', @(object,event)setCImarker(ax,arcHandle));
% % draw a stalk from the center
% meanHandle = polarplot([th th],[0 ax.RLim(2)],'LineWidth',1,'Color',darkGreyCol);
% uistack(meanHandle,'bottom')
end
[~,pVal] = ttest(weightingVector,0,'Tail','right');

% % add stats info to plot for convenience:
% text(ax,-80,ax.RLim(2)+0.05,{[num2str(r,'%.2f') ', ' num2str(rad2deg(th),'%.2f') char(176)]; ['CI:' num2str(rad2deg(t),'%.2f') char(176)]},'FontSize',axisLabelFontSize);
% % print instead:
fprintf(['\n[resultant(non-axial)|pix|PSIthresh=%d|PSIweight=%d)]\n N=%d, p=%1.5f tailed t-test\n mean length:%1.2f, SEM:%1.2f\n\n'],...
usePSIthreshold,...
usePSIweighting,...
populationSize,...
pVal,...
nanmean(vecLengthArray),...
nanstd(vecLengthArray)/sqrt(populationSize) ...
);

tightfig(f)
addExportFigToolbar(gcf)
%%

% old version with a mean line +/- sem using polygonplot
%{

figure
clear opt_axes opt_area opt_lines
   polcols = flipud(hsv(180));
    opt_area.Color = darkGreyCol;%polcols(ROIang,:);
    opt_area.err = 'sem';
    opt_area.FaceAlpha = 0.5;
    
    
    opt_lines.LineWidth = 1;
    opt_lines.Color = darkGreyCol;%polcols(ROIang,:);
%     opt_axes.Ticks = [0:0.25:1];
    opt_axes.NRadii = 12;
    opt_axes.Labels     = {['  -90' char(176)],'','','','','',['  90' char(176)],'','',['  0' char(176)],'',''};
%     opt_axes.Labels     = {['  -90' char(176)],'','',['180' char(176)],'','',['90' char(176) ' '],'','',['0' char(176)],'',''};
    clear alldata
    alldata(:,1,:) = [fly_mean_traces'; fly_mean_traces'] ;
%     alldata = alldata./(max(alldata,[],1)); % normalize each fly trace
   
    

    polygonplot(alldata,opt_axes,opt_lines,opt_area);
    hold on
    
    %% individual fly histograms
    if plotIndividFlies || plotIndividExps
    indivdata(:,:,1) = [fly_mean_traces'; fly_mean_traces'] ;
%     indivdata = indivdata./(max(indivdata,[],1)); % normalize each fly trace
    
    polygonplot(indivdata);
    end
        %%
    ylim([0 1])
        xlim([-1 1])
        pbaspect([ 1 0.5 1])
        %%

%         % Add mean tuning pref line:
%         pixPolWeight = mean(squeeze(alldata),2)';
%         polAngs = wrapTo180(-circshift([30:30:360],-5)-270);
%         [r,axtheta] = circ_rangle(circ_axial(deg2rad(polAngs),2), pixPolWeight, deg2rad(mode(diff(polAngs))), 2);
%         theta = axtheta/2;
%         Ang =0.5.*(wrapTo180((2.*(rad2deg(theta)))));
%         hold on
%         R  = [0; 1];
%         TH = [deg2rad(Ang-90) deg2rad(Ang-270)].*ones(2,2);
%
%         [X,Y] = pol2cart(TH, R);
%
%          for n = 1:2,  plot(X(2,:),Y(2,:),'color',polcols(ROIang,:),'LineWidth',2,'LineStyle',':'); end
%
setAVPaxes(gca,2.5)
tightfig(gcf)

%}

end
function setCImarker(pax,arcHandle)
upper  = pax.RLim(2);
for aIdx = 1:length(arcHandle)
    arcHandle(aIdx).RData = ones(size(arcHandle(aIdx).RData)).*upper;
end
end