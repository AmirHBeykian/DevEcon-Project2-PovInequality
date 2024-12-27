# DevEcon-Project2-PovertyInequality
Hi!

This project is rendered using [Quarto](https://quarto.org/).

The source code file is `main.qmd`, located in the root directory. To view the
report, please clone the entire repository and open `Report/main.html` in a web
browser.

If you prefer to run the code without installing Quarto, you can execute the
`main_r.rmd` file, which contains the exact same code chunks.

### Data Cleaning Process
The HEIS data are cleaned in two steps.

First, using STATA, the `.mdb`
file is transformed into many `.dta` files. So if you want to reproduce the results using
the original dataset, please first run `heis-cleaning.do` file. (Note that you should first
define appropriate ODBC sources on you computer.) This generates `.dta` files in the `Data`
directory.

Second, the code chunks in the appendix section of the report, do the rest of the cleaning
by transforming these `.dta` files into three `.rds` files which are then used to produce
the results. 