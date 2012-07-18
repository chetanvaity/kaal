#!/usr/bin/python

from gensim import corpora, models, similarities

CORPUSFILE='/media/My Passport/timeline/en-wiki/txt-articles/bollywood-clean.txt'
#CORPUSFILE='/media/My Passport/timeline/en-wiki/txt-articles/sample.txt'

stoplist = set('a able about across after all almost also am among an and any are as at be because been but by can cannot could dear did do does either else ever every for from get got had has have he her hers him his how however i if in into is it its just least let like likely may me might most must my neither no nor not of off often on only or other our own rather said say says she should since so some than that the their them then there these they this tis to too twas us wants was we were what when where which while who whom why will with would yet you your'.split())

# First lets store the doc names
docnames = {}
i = 1
for line in open(CORPUSFILE):
    docnames[i] = line[:20]
    i = i + 1

dictionary = corpora.Dictionary(line.lower().split() for line in open(CORPUSFILE))

stop_ids = [dictionary.token2id[stopword] for stopword in stoplist
            if stopword in dictionary.token2id]
dictionary.filter_tokens(stop_ids)
dictionary.compactify()

class MyCorpus(object):
    def __iter__(self):
        for line in open(CORPUSFILE):
            # assume there's one document per line, tokens separated by whitespace
            yield dictionary.doc2bow(line.lower().split())

corpus = MyCorpus()

tfidf = models.TfidfModel(corpus)
corpus_tfidf = tfidf[corpus]
docid=1
for doc in corpus_tfidf:
    for tuple in doc:
        print docnames[docid] + "," + dictionary[tuple[0]] + "," + str(tuple[1])
        pass
    docid = docid+1

