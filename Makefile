# DATA_FILES := $(wildcard data/public/*.zip)

# all: $(DATA_FILES)

data/public/GWF_autocratic_regimes.zip:
	cd data/public;curl -o GWF_autocractic_regimes.zip "http://sites.psu.edu/dictators/wp-content/uploads/sites/12570/2014/07/GWF-Autocratic-Regimes-1.2.zip"
