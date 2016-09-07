clear all

PointsAlphaMask = imread('Points\Table1 Region1 Ch1 Points.png');
PointsAlphaMask = im2bw(PointsAlphaMask);
PointsAlphaMask = ~PointsAlphaMask;

ClusterMask2 = imread('Thr-Clusters\blobs\Table1 Region1 Ch1 Clusters by blobs.png');


 
% render points over Blobs    
    pointsonblobs = figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'pixels');
    axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
    box('off');
    set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');
    imshow(ClusterMask2, 'InitialMag', 'fit');
    axis square tight image
    set(gca,'XTickLabel','','YTickLabel','','XTick', [],'YTick', [])

    % Make a truecolor all-green image.
    green = cat(3, zeros(size(ClusterMask2)),ones(size(ClusterMask2)),zeros(size(ClusterMask2)));
    hold on 
    pointsoverlay = imshow(green); 
    hold off
    set(pointsoverlay, 'AlphaData', PointsAlphaMask);
    SavePNG('Thr-Clusters\Blobs\WithPoints',strcat(ImgFileName,' points overlay'),ProcSet.UseFolders);
    close(pointsonblobs);
    clear green pointsoverlay pointsonblobs