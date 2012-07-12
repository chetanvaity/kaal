#!/usr/bin/python

import sys
from nltk.corpus import wordnet as wn

MAX_SENSE_COUNT=1

# Return a list of words which are derivationnaly related to word
def get_tset(word):
    ss = wn.synsets(word)
    if len(ss) == 0:
        return [word]
    
    sense_count = 1
    tset = []
    for s in ss:
        if sense_count > MAX_SENSE_COUNT:
            break
        tset.extend(s.lemma_names)
        lemmas = s.lemmas
        for l in lemmas:
            for der_l in l.derivationally_related_forms():
                der_s = der_l.synset
                tset.extend(der_s.lemma_names)
        sense_count = sense_count + 1

    return remove_dups(tset)

# Remove duplicate elements from a list - preserving order
def remove_dups(inlist):
    outlist = []
    for element in inlist:
        if element not in outlist:
            outlist.append(element)
    return outlist

### Main Script ###

if len(sys.argv) != 3:
    print "Usage: make_tsets.py infile outfile"
    exit(1)

infile = sys.argv[1]
outfile = sys.argv[2]

inf = open(infile)
outf = open(outfile, "w")

for line in inf:
    word = line.strip()
    tset = get_tset(word)
    if len(tset) > 1:
        outf.write('\t'.join(tset))
        outf.write('\n')

inf.close
outf.close
