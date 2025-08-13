function [comp, shell, outFlag] = get_build_cmd(lang)
arguments (Input)
  lang (1,1) string {mustBeMember(lang, ["c", "c++", "fortran"])}
end
arguments (Output)
  comp string {mustBeScalarOrEmpty}
  shell string {mustBeScalarOrEmpty}
  outFlag (1,1) string
end

[comp, shell] = get_compiler(lang);

if any(contains(shell, "Visual Studio")) || endsWith(comp, "ifx.exe")
  outFlag = "/Fo" + tempdir + " /link /out:";
else
  outFlag = "-o";
end

end
