DATA_FILES := $(wildcard data/public/*)

all: $(DATA_FILES)

GWF_autocratic_regimes.zip:
	curl -o GWF_autocractic_regimes.zip "http://sites.psu.edu/dictators/wp-content/uploads/sites/12570/2014/07/GWF-Autocratic-Regimes-1.2.zip"

GWF-Autocratic-Regimes-1.2.zip:
	curl -o GWF-Autocratic-Regimes-1.2.zip "http://sites.psu.edu/dictators/wp-content/uploads/sites/12570/2014/07/GWF-Autocratic-Regimes-1.2.zip"

GWF_AllPoliticalRegimes.txt:
	unzip GWF-Autocratic-Regimes-1.2.zip
	touch GWF_AllPoliticalRegimes.txt
