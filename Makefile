# $Id: Makefile,v 1.14 1999-09-03 17:24:37 nik Exp $

#
# The user can override the default list of languages to build and install
# with the DOC_LANG variable.
# 
.if defined(DOC_LANG) && !empty(DOC_LANG)
SUBDIR = 	${DOC_LANG}
.else
SUBDIR =	en_US.ISO_8859-1
SUBDIR+=	es_ES.ISO_8859-1
SUBDIR+=	ja_JP.eucJP
SUBDIR+=	ru_RU.KOI8-R
SUBDIR+=	zh_TW.Big5
.endif

DOC_PREFIX?=   ${.CURDIR}
.include "${DOC_PREFIX}/share/mk/doc.subdir.mk"
