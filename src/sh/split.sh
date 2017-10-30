NLINES=1000
FILENAME=user_artist_data
# Split with head and echo result
head -n$NLINES $FILENAME.txt > $FILENAME_$NLINES.txt
