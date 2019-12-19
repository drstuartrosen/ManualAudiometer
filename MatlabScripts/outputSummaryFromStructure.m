function [varNames, varValues] = outputSummaryFromStructure(p)

varNames=[];
allTheFields = fieldnames(p);
% output all the field names on one row
for i=1:length(allTheFields)
    varNames=strcat(varNames, sprintf('%s,', allTheFields{i}));
end
% excise last comma
varNames(end)=[];
strcat(varNames,'\n');

varValues=[];
for i=1:length(allTheFields)
    xx = getfield(p,allTheFields{i});
    if ischar(xx)
        varValues=strcat(varValues, sprintf('%s,', xx));
    else
        if length(xx)<2 % one value only
            varValues=strcat(varValues, sprintf('%g,', xx));
        elseif length(xx)<5 % want to have all values in one column
            yy=sprintf('%g-', xx);
            yy(end)=[]; % take off extra dash
            varValues=strcat(varValues, yy,',');          
        else % just too many numbers!
            varValues=strcat(varValues, ' ,');
        end
    end
end
% excise last comma
varValues(end)=[];
strcat(varValues,'\n');
