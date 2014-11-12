all: GWF_Autocratic_Regimes_1_2

GWF-Autocratic-Regimes-1.2.zip:
	curl -o GWF-Autocratic-Regimes-1.2.zip "http://sites.psu.edu/dictators/wp-content/uploads/sites/12570/2014/07/GWF-Autocratic-Regimes-1.2.zip"

GWF_Autocratic_Regimes_1_2: GWF-Autocratic-Regimes-1.2.zip
	unzip GWF-Autocratic-Regimes-1.2.zip
	mv GWF\ Autocratic\ Regimes\ 1.2 GWF_Autocratic_Regimes_1_2
	find ./GWF_Autocratic_Regimes_1_2 -exec touch {} \;
	rm GWF-Autocratic-Regimes-1.2.zip
