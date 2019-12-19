function outPutOneTonePlayed(g, fileOut)

if nargin<2
    fileOut=g.OutFile;
end
%     fprintf(fout, 'listener,date,time,trial,ear,frq,atten,rTime');
fout = fopen(fileOut, 'at');
if g.channel==0
    ear='L';
else
    ear='R';
end
fprintf(fout, '%s,%s,%s,%d,%c,%d,%d,%d,', ...
    g.I,g.StartDate,g.StartTimeString,g.trial,ear,g.tone,g.att+g.maxdBHL,g.att);
TimeOfResponse = clock;
ToR = sprintf('%02d:%02d:%05.2f',TimeOfResponse(4),TimeOfResponse(5),TimeOfResponse(6));
fprintf(fout, '''%s''\n',ToR);
fclose(fout);
