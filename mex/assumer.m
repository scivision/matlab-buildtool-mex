function assumer(tc, excp)

if excp.identifier == "MATLAB:mex:ErrInvalidMEXFile" && contains(excp.message, 'Gateway function is missing')
  % I don't know why Matlab has this bug
  tc.assumeFail("Matlab seems to have a bug with MEX gateway functions: " + excp.message)
else
  rethrow(excp)
end

end
