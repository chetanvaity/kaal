#!/bin/sh

YEAR=$1

DUMP=wiki-$YEAR.dump

#wget -O $DUMP "http://en.wikipedia.org/w/api.php?format=xml&action=query&titles=$YEAR&prop=revisions&rvprop=content"
#if [ $? -ne 0 ]; then
#    echo "wget failed for year $YEAR"
#    exit 1
#fi

seperate_sections.rb -f wiki-$YEAR.dump
if [ $? -ne 0 ]; then
    echo "seperate_sections.rb failed for $DUMP"
    exit 1
fi

#
# Now we have files called wiki-$YEAR.dump.births, events and deaths
#
for section in events births deaths; do
    clean_markup.rb -f $DUMP.$section > $DUMP.$section.cleaned
    if [ $? -ne 0 ]; then
	echo "clean_markup.rb failed for $DUMP.$section"
	exit 1
    fi
done

# If all went well. lets remove the temporary files
#rm -f $DUMP 
#for section in events births deaths; do
#    rm -f $DUMP.$section
#done
