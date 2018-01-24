sysuse auto
eststo clear
eststo: regress price weight mpg
eststo: regress price weight mpg foreign
esttab using example.tex, label nostar ///
title(Regression table\label{tab1}) replace


mata
S=("\documentclass[11pt,letterpaper]{article}")
S=(S\"\setlength{\voffset}{-1in}")
S=(S\"\setlength{\hoffset}{-1in} ")
S=(S\"\setlength{\topmargin}{0.1in}")
S=(S\"\setlength{\headheight}{0.8in}")
S=(S\"\setlength{\headsep}{0.1in}")
S=(S\"\setlength{\textheight}{9in}")
S=(S\"\setlength{\oddsidemargin}{1in}")
S=(S\"\setlength{\textwidth}{6.5in}")
S=(S\"\begin{document}")
S=(S\"\input{example.tex}")
S=(S\"\end{document}")


f=fopen("main.tex","rw")
for(i=1;i<=rows(S);i++){
	fput(f,S[i])
}
fclose(f)
end

*Below for windows.
*shell "C:/Program Files (x86)/MiKTeX 2.9/miktex/bin/pdflatex.exe" main.tex

*Below for unix
shell pdflatex main.tex
