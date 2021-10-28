function fcsfile = fcssetparam(fcsfile,parname,parval)
%fcsfile=fcssetparam(fcsfile,parname,parval)

for index=1:length(fcsfile)
    id=strcmp(fcsfile(index).var_name,parname);
    if sum(id)==1
        fcsfile(index).var_value{id}=parval;
    else
        fcsfile(index).var_name{end+1}=parname;
        fcsfile(index).var_value{end+1}=parval;
    end
end
end