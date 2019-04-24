%%

clear;
clc;
drct = director();
set(drct, 'file', 'test');
set(drct, 'duration', 6);

drct.addAnimatedVariable('y');
drct.addKeyframe('y', [0 1 2 3 4 5 6], [0 0.6 0 1 0 0.6 0], [2 2 2 2 2 2 2]);

figure;
dx = [];
dy = [];
for ii = get(drct, 'ticks')
    
    update(drct);
    d = get(drct, 'currentState');
    
    dx = [dx d.time];
    dy = [dy d.y];
    plot(dx, dy, 'ow', 'MarkerFaceColor', 'w');
    set(gcf, 'Color', 'k');
    set(gca, 'Color', 'k');
    set(gca, 'XColor', 'w');
    set(gca, 'YColor', 'w');
    xlim([0 6]);
    ylim([0 1]);
    drawnow();
    
    drct.saveFrame();
    
end

