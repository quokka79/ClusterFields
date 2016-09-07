imgtest = imread('Table1 Region1 Ch1 Clusters by blobs.png');






% Generate the plots
figure('Color',[1 1 1], 'Visible', 'off', 'Renderer', 'OpenGL', 'Units', 'pixels');
axes('Parent',figure,'Layer','top', 'YTick',zeros(1,0),'XTick',zeros(1,0),'DataAspectRatio', [1,1,1],'position',[0,0,1,1]);            
box('off');
hold('on');
set(gcf, 'PaperUnits', 'inches', 'PaperSize', [10 10], 'PaperPositionMode', 'manual', 'PaperPosition', [0 0 10 10],'Visible','off');
axis square image
set(gca, 'Visible','off');
set(gcf, 'Visible','on');

imshow(imgtest);
img2 = bwmorph(imgtest,'shrink',10);
img2 = bwmorph(img2,'spur');
img2 = bwmorph(img2,'clean');
imshow(img2);

SavePNG('D:\[ Sync ]\Work\Sandpit\17f\Thr-Clusters\Blobs','ten rounds.png',true);