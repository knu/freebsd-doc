# bsd.web.mk
# $FreeBSD: www/share/mk/web.site.mk,v 1.40 2001/11/12 19:17:39 phantom Exp $

#
# Build and install a web site.
#
# Basic targets:
#
# all (default) -- performs batch mode processing necessary
# install -- Installs everything
# clean -- remove anything generated by processing
#

.if exists(${.CURDIR}/../Makefile.inc)
.include "${.CURDIR}/../Makefile.inc"
.endif

WEBDIR?=	${.CURDIR:T}
CGIDIR?=	${.CURDIR:T}
DESTDIR?=	${HOME}/public_html

WEBOWN?=	${USER}
WEBGRP?=	www
WEBMODE?=	664

CGIOWN?=	${USER}
CGIGRP?=	www
CGIMODE?=	775

CP?=		/bin/cp
CVS?=		/usr/bin/cvs
ECHO_CMD?=	echo
SETENV?=	/usr/bin/env
LN?=		/bin/ln
MKDIR?=		/bin/mkdir
MV?=		/bin/mv
PERL?=		/usr/bin/perl5
RM?=		/bin/rm
SED?=		/usr/bin/sed
SH?=		/bin/sh
SORT?=		/usr/bin/sort
TOUCH?=		/usr/bin/touch

XSLTPROC?=	${PREFIX}/bin/xsltproc
XSLTPROCOPTS?=	-nonet ${XSLTPROCFLAGS}
TIDY?=		${PREFIX}/bin/tidy
TIDYOPTS?=	-i -m -raw -preserve -f /dev/null ${TIDYFLAGS}

#
# Install dirs derived from the above.
#
DOCINSTALLDIR=	${DESTDIR}${WEBBASE}/${WEBDIR}
CGIINSTALLDIR=	${DESTDIR}${WEBBASE}/${CGIDIR}

#
# The orphan list contains sources specified in DOCS that there
# is no transform rule for.  We start out with all of them, and
# each rule below removes the ones it knows about.  If any are
# left over at the end, the user is warned about them.
#
ORPHANS:=	${DOCS}

COPY=	-C

#
# Where the ports live, if CVS isn't used (ie. NOPORTSCVS is defined)
#
PORTSBASE?=	/usr

##################################################################
# Transformation rules

###
# file.sgml --> file.html
#
# Runs file.sgml through spam to validate and expand some entity
# references are expanded.  file.html is added to the list of
# things to install.

.SUFFIXES:	.sgml .html
.if defined(REVCHECK)
PREHTML?=	${WEB_PREFIX}/ja/prehtml
CANONPREFIX0!=	cd ${WEB_PREFIX}; ${ECHO_CMD} $${PWD};
CANONPREFIX=	${PWD:S/^${CANONPREFIX0}//:S/^\///}
LOCALTOP!=	${ECHO_CMD} ${CANONPREFIX} | \
	${PERL} -pe 's@[^/]+@..@g; $$_.="/." if($$_ eq".."); s@^\.\./@@;'
DIR_IN_LOCAL!=	${ECHO_CMD} ${CANONPREFIX} | ${PERL} -pe 's@^[^/]+/?@@;'
PREHTMLOPTS?=	-revcheck "${LOCALTOP}" "${DIR_IN_LOCAL}" ${PREHTMLFLAGS}
.else
DATESUBST?=	's/<!ENTITY date[ \t]*"$$Free[B]SD. .* \(.* .*\) .* .* $$">/<!ENTITY date	"Last modified: \1">/'
PREHTML?=	${SED} -e ${DATESUBST}
.endif
.if !defined(OPENJADE)
SGMLNORM?=	${PREFIX}/bin/sgmlnorm
.else
SGMLNORM?=	${PREFIX}/bin/osgmlnorm
.endif
LOCALBASE?=	/usr/local
PREFIX?=	${LOCALBASE}
CATALOG?=	${PREFIX}/share/sgml/html/catalog
SGMLNORMOPTS?=	-d ${SGMLNORMFLAGS} -c ${CATALOG} -D ${.CURDIR}
GENDOCS+=	${DOCS:M*.sgml:S/.sgml$/.html/g}
ORPHANS:=	${ORPHANS:N*.sgml}

.sgml.html:
	${PREHTML} ${PREHTMLOPTS} ${.IMPSRC} | \
	${SETENV} SGML_CATALOG_FILES= \
		${SGMLNORM} ${SGMLNORMOPTS} > ${.TARGET} || \
			(${RM} -f ${.TARGET} && false)
.if !defined(NO_TIDY)
	-${TIDY} ${TIDYOPTS} ${.TARGET}
.endif

###
# file.docb --> file.html
#
# Generate HTML from docbook

SGMLFMT?=	${PREFIX}/bin/sgmlfmt
SGMLFMTOPTS?=	-d docbook -f html ${SGMLFMTFLAGS} ${SGMLFLAGS}
.SUFFIXES:	.docb
GENDOCS+=	${DOCS:M*.docb:S/.docb$/.html/g}
ORPHANS:=	${ORPHANS:N*.docb}

.docb.html:
	${SGMLFMT} ${SGMLFMTOPTS} ${.IMPSRC}
.if !defined(NO_TIDY)
	-${TIDY} ${TIDYOPTS} ${.TARGET}
.endif


##################################################################
# Targets

#
# If no target is specified, .MAIN is made
#
.MAIN: all

#
# Build most everything
#
all: ${COOKIE} orphans ${GENDOCS} ${DATA} ${LOCAL} ${CGI} _PROGSUBDIR

#
# Warn about anything in DOCS that has no translation
#
.if !empty(ORPHANS)
orphans:
	@${ECHO} Warning!  I don\'t know what to do with: ${ORPHANS}
.else
orphans:
.endif

#
# Clean things up
#
.if !target(clean)
clean: _PROGSUBDIR
.if defined(DIRS_TO_CLEAN) && !empty(DIRS_TO_CLEAN)
.for dir in ${DIRS_TO_CLEAN}
	cd ${.CURDIR}/${dir}; ${MAKE} clean
.endfor
.endif
	${RM} -f Errs errs mklog ${GENDOCS} ${LOCAL} ${CLEANFILES}
.endif

#
# Really clean things up
#
.if !target(cleandir)
cleandir: clean _PROGSUBDIR
	${RM} -f ${.CURDIR}/tags .depend
	cd ${.CURDIR}; ${RM} -rf obj
.endif

#
# Install targets: before, real, and after.
#
.if !target(install)
.if !target(beforeinstall)
beforeinstall:
.endif
.if !target(afterinstall)
afterinstall:
.endif

INSTALL_WEB?=	\
	${INSTALL} ${COPY} ${INSTALLFLAGS} -o ${WEBOWN} -g ${WEBGRP} -m ${WEBMODE}
INSTALL_CGI?=	\
	${INSTALL} ${COPY} ${INSTALLFLAGS} -o ${CGIOWN} -g ${CGIGRP} -m ${CGIMODE}
_ALLINSTALL+=	${GENDOCS} ${DATA} ${LOCAL}

realinstall: ${COOKIE} ${_ALLINSTALL} ${CGI} _PROGSUBDIR
.if !empty(_ALLINSTALL)
	@${MKDIR} -p ${DOCINSTALLDIR}
.for entry in ${_ALLINSTALL}
.if exists(${.CURDIR}/${entry})
	${INSTALL_WEB} ${.CURDIR}/${entry} ${DOCINSTALLDIR}
.else
	${INSTALL_WEB} ${entry} ${DOCINSTALLDIR}
.endif
.endfor
.if defined(INDEXLINK) && !empty(INDEXLINK)
	cd ${DOCINSTALLDIR}; ${LN} -fs ${INDEXLINK} index.html
.endif
.endif
.if defined(CGI) && !empty(CGI)
	@${MKDIR} -p ${CGIINSTALLDIR}
.for entry in ${CGI}
	${INSTALL_CGI} ${.CURDIR}/${entry} ${CGIINSTALLDIR}
.endfor
.endif
.if defined(DOCSUBDIR) && !empty(DOCSUBDIR)
.for entry in ${DOCSUBDIR}
	@${MKDIR} -p ${DOCINSTALLDIR}/${entry}
.endfor
.endif

# Set up install dependencies so they happen in the correct order.
install: afterinstall
afterinstall: realinstall2
realinstall: beforeinstall
realinstall2: realinstall
.endif 

#
# This recursively calls make in subdirectories.
#
#SUBDIR+=${DOCSUBDIR}
_PROGSUBDIR: .USE
.if defined(SUBDIR) && !empty(SUBDIR)
.for entry in ${SUBDIR}
	@${ECHODIR} "===> ${DIRPRFX}${entry}"
	@cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/
.endfor
.endif
.if defined(DOCSUBDIR) && !empty(DOCSUBDIR)
.for entry in ${DOCSUBDIR}
	@${ECHODIR} "===> ${DIRPRFX}${entry}"
	@if [ \( "${WEBDIR}" = "data" -a "${entry}" = "handbook" \) -o "${entry}" = "docproj-primer" ]; then \
		cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/ ${PARAMS} \
			FORMATS="txt html html-split"; \
	elif [ "${WEBDIR}" = "data/ja" -a "${entry}" = "handbook" ]; then \
		cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/ ${PARAMS} \
			FORMATS="html html-split"; \
	else \
		cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/ ${PARAMS}; \
	fi
.endfor
.endif

#
# cruft for generating linuxdoc stuff
#

.if defined (DOCSUBDIR) && !empty(DOCSUBDIR)

FORMATS?=	"html ps latin1 ascii"
PARAMS=		DESTDIR=${DESTDIR} DOCDIR=${WEBBASE}/${WEBDIR}
PARAMS+=	DOCOWN=${WEBOWN} DOCGRP=${WEBGRP}
PARAMS+=	FORMATS=${FORMATS} COPY="${COPY}"
PARAMS+=	SGMLOPTS="${SGMLOPTS}"

.endif

.include <bsd.obj.mk>

# THE END
