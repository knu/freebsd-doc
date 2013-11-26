# bsd.web.mk
# $FreeBSD$

#
# Build and install a web site.
#
# Basic targets:
#
# all (default) -- performs batch mode processing necessary
# install -- installs everything
# clean -- remove anything generated by processing
#

.include "doc.commands.mk"

.if exists(${.CURDIR}/../Makefile.inc)
.include "${.CURDIR}/../Makefile.inc"
.endif

WEBDIR?=	${.CURDIR:T}
CGIDIR?=	${.CURDIR:T}
DESTDIR?=	${HOME}/public_html

_ID?=		/usr/bin/id
_UID!=		${_ID} -u

WEBOWN?=	${USER}
.if (${_UID} > 0)
WEBGRP?=	${USER}
.else
WEBGRP?=	www
.endif
WEBMODE?=	664

CGIOWN?=	${USER}
.if (${_UID} > 0)
CGIGRP?=	${USER}
.else
CGIGRP?=	www
.endif
CGIMODE?=	775

LOCALBASE?=	/usr/local
PREFIX?=	${LOCALBASE}

XSLTPROCOPTS?=	${XSLTPROCFLAGS}
XMLLINTOPTS?=	${XMLLINTFLAGS}

WEBCHECK?=	${PREFIX}/bin/webcheck
WEBCHECKOPTS?=	-ab ${WEBCHECKFLAGS}
WEBCHECKDIR?=	/webcheck
WEBCHECKINSTALLDIR?= ${DESTDIR}${WEBCHECKDIR} 
.if !defined(WEBCHECKURL)
WEBCHECKURL!=	${ECHO_CMD} http://www.FreeBSD.org/${WEBBASE:S/data//}/${WEBDIR:S/data//}/ | ${SED} -E "s%/+%/%g"
.endif

#
# Install dirs derived from the above.
#
DOCINSTALLDIR=	${DESTDIR}${WEBBASE}/${WEBDIR}
CGIINSTALLDIR=	${DESTDIR}${WEBBASE}/${CGIDIR}

#
# The orphan list contains sources specified in DOCS that there
# is no transform rule for.  We start out with all of them, and
# each rule below removes the ones it knows about.  If any are
# left over at the end, the user is warned about them and build
# breaks.
#
ORPHANS:=	${DOCS}

#
# Tell install(1) to always copy file being installed.
#
COPY=	-C

#
# Where the ports live, if CVS isn't used (ie. NOPORTSCVS is defined)
#
PORTSBASE?=	/usr

#
# URL where INDEX can be found (define NOPORTSNET to disable)
#
INDEXURI?=	http://www.FreeBSD.org/ports/INDEX-8

#
# Instruct bsd.subdir.mk to NOT to process SUBDIR directive.  It is not
# necessary since web.site.mk does it using own rules.
#
NO_SUBDIR=	YES

#
# for dependency
#
.include "${DOC_PREFIX}/share/mk/doc.common.mk"
.include "${DOC_PREFIX}/share/mk/doc.xml.mk"

##################################################################
# Transformation rules

###
# file.xml --> file.html
#
# Runs file.xml through spam to validate and expand some entity
# references are expanded.  file.html is added to the list of
# things to install.

.SUFFIXES:	.xml .html
.if defined(REVCHECK)
PREHTML?=	${DOC_PREFIX}/ja_JP.eucJP/htdocs/prehtml
CANONPREFIX0!=	cd ${DOC_PREFIX}; ${ECHO_CMD} $${PWD};
CANONPREFIX=	${PWD:S/^${CANONPREFIX0}//:S/^\///}
LOCALTOP!=	${ECHO_CMD} ${CANONPREFIX} | \
	${PERL} -pe 's@[^/]+@..@g; $$_.="/." if($$_ eq".."); s@^\.\./@@;'
DIR_IN_LOCAL!=	${ECHO_CMD} ${CANONPREFIX} | ${PERL} -pe 's@^[^/]+/?@@;'
PREHTMLOPTS?=	-revcheck "${LOCALTOP}" "${DIR_IN_LOCAL}" ${PREHTMLFLAGS}
.else
# Force override base to point to http://www.FreeBSD.org/.  Note: This
# is used for http://security.FreeBSD.org/ .
.if WITH_WWW_FREEBSD_ORG_BASE
PREHTML?=	${SED} -e 's/<!ENTITY base CDATA ".*">/<!ENTITY base CDATA "http:\/\/www.FreeBSD.org">/'
.endif
.endif

GENDOCS+=	${DOCS:M*.xml:S/.xml$/.html/g}
ORPHANS:=	${ORPHANS:N*.xml}

.xml.html: ${_DEPENDSET.wwwstd} ${DOC_PREFIX}/share/xml/xhtml.xsl
.if defined(PREHTML)
	${PREHTML} ${PREHTMLOPTS} ${.IMPSRC} > ${.IMPSRC}-tmp
	${XMLLINT} ${XMLLINTOPTS} ${.IMPSRC}-tmp
	${XSLTPROC} ${XSLTPROCOPTS} --debug -o ${.TARGET} \
	    http://www.FreeBSD.org/XML/share/xml/xhtml.xsl ${.IMPSRC}-tmp || \
	    (${RM} -f ${.IMPSRC}-tmp ${.TARGET} && false)
	${RM} -f ${.IMPSRC}-tmp
.else
	${XMLLINT} ${XMLLINTOPTS} ${.IMPSRC}
	${XSLTPROC} ${XSLTPROCOPTS} --debug -o ${.TARGET} \
	    http://www.FreeBSD.org/XML/share/xml/xhtml.xsl ${.IMPSRC}
.endif

##################################################################
# Special Targets

#
# Spellcheck all generated documents in the current directory.
#
spellcheck:
.for _entry in ${GENDOCS}
	@echo "Spellcheck ${_entry}"
	@${HTML2TXT} ${HTML2TXTOPTS} ${.OBJDIR}/${_entry} | ${ISPELL} ${ISPELLOPTS}
.endfor

#
# Check installed page's hypertext references.  Checking is done relatively
# to ${.CURDIR} value, i.e. calling 'make webcheck' in www/ru/java
# directory will force checking all URLs at http://www.FreeBSD.org/ru/java/
#
# NOTE: webcheck's output always stored to ${DESTDIR}/webcheck directory.
#
webcheck:
	@[ -d ${WEBCHECKINSTALLDIR} ] || ${MKDIR} ${WEBCHECKINSTALLDIR}
	${WEBCHECK} ${WEBCHECKOPTS} -o ${WEBCHECKINSTALLDIR} ${WEBCHECKURL}

#
# Check if all directories and files in current directory are listed in
# Makefile as processing source.  If anything not listed is found, then
# user is warned about (it can be forgotten file or directory).
#
.if make(checkmissing)
# skip printing '===> ...' while processing SUBDIRs
ECHODIR=	${TRUE}

# detect relative ${.CURDIR}
_CURDIR!=	realpath ${.CURDIR}
_PFXDIR!=	realpath ${DOC_PREFIX}
CDIR=		${_CURDIR:S/${_PFXDIR}\///}

# populate missing directories list based on $SUBDIR
_DIREXCL=	! -name CVS
.for entry in ${SUBDIR}
_DIREXCL+=	! -name ${entry}
.endfor
MISSDIRS!=	${FIND} ./ -type d ${_DIREXCL} -maxdepth 1 | ${SED} "s%./%%g"

# populate missing files list based on $DOCS, $DATA and $CGI
_FILEEXCL=	! -name Makefile\* ! -name includes.\*
.for entry in ${DOCS} ${DATA} ${CGI}
_FILEEXCL+=	! -name ${entry}
.endfor
MISSFILES!=	${FIND} ./ -type f ${_FILEEXCL} -maxdepth 1 | ${SED} "s%./%%g"

checkmissing:	_PROGSUBDIR
.if !empty(MISSDIRS)
	@${ECHO_CMD} "===> ${CDIR}"
	@${ECHO_CMD} "Directories not listed in SUBDIR:"
.for entry in ${MISSDIRS}
	@${ECHO_CMD} "    >>> ${entry}"
.endfor
.endif
.if !empty(MISSFILES)
	@${ECHO_CMD} "===> ${CDIR}"
	@${ECHO_CMD} "Files not listed in DOCS/DATA/CGI:"
.for entry in ${MISSFILES}
	@${ECHO_CMD} "    >>> ${entry} "
.endfor
.endif
.endif

##################################################################
# Main Targets

#
# If no target is specified, .MAIN is made.
#
.MAIN: all

#
# Build most everything.
#
all: ${COOKIE} orphans ${GENDOCS} ${DATA} ${CGI} _PROGSUBDIR

#
# Warn about anything in DOCS that has no suffix translation rule.
#
.if !empty(ORPHANS)
orphans:
	@${ECHO} Warning!  I don\'t know what to do with: ${ORPHANS}; \
	exit 1
.else
orphans:
.endif

#
# Clean things up.
#
.if !target(clean)
clean: _PROGSUBDIR
	${RM} -f Errs errs mklog ${GENDOCS} ${CLEANFILES}
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
	${INSTALL} ${COPY} ${INSTALLFLAGS} \
				-o ${WEBOWN} -g ${WEBGRP} -m ${WEBMODE}
INSTALL_CGI?=	\
	${INSTALL} ${COPY} ${INSTALLFLAGS} \
				-o ${CGIOWN} -g ${CGIGRP} -m ${CGIMODE}
_ALLINSTALL+=	${GENDOCS} ${DATA}

realinstall: ${COOKIE} ${_ALLINSTALL} ${CGI} _PROGSUBDIR
.if !empty(_ALLINSTALL) || !empty(BULKDATADIRS)
	@${MKDIR} -p ${DOCINSTALLDIR}
.for entry in ${BULKDATADIRS}
	@(cd ${entry} && \
	${FIND} * -type d -exec ${MKDIR} -p ${DOCINSTALLDIR}/{} \; )
.endfor
.for entry in ${_ALLINSTALL}
.if exists(${.CURDIR}/${entry})
	${INSTALL_WEB} ${.CURDIR}/${entry} ${DOCINSTALLDIR}
.else
	${INSTALL_WEB} ${entry} ${DOCINSTALLDIR}
.endif
.endfor
.for entry in ${BULKDATADIRS}
	@(cd ${entry} && \
	${FIND} * -type f -exec ${INSTALL_WEB} ${entry}/{} ${DOCINSTALLDIR}/{} \; )
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

_installlinks:
.if defined(SYMLINKS) && !empty(SYMLINKS)
	@(${ECHO_CMD} "====> Creating symlinks in ${DOCINSTALLDIR}" && \
	cd ${DOCINSTALLDIR} && \
	set ${SYMLINKS}; \
	while test $$# -ge 2; do \
		l=$$1; \
		shift; \
		t=$$1; \
		shift; \
		${ECHO_CMD} $$t -\> $$l; \
		${LN} -fs $$l $$t; \
	done )
.endif

# Set up install dependencies so they happen in the correct order.
install: afterinstall
afterinstall: _installlinks
_installlinks: realinstall2
realinstall: beforeinstall
realinstall2: realinstall
.endif 

#
# This recursively calls make in subdirectories.
#
_PROGSUBDIR: .USE
.if defined(SUBDIR) && !empty(SUBDIR)
.for entry in ${SUBDIR}
	@${ECHODIR} "===> ${DIRPRFX}${entry}"
	@cd ${.CURDIR}/${entry}; \
		${MAKE} ${.TARGET:S/realinstall/install/:S/.depend/depend/} \
			DIRPRFX=${DIRPRFX}${entry}/
.endfor
.endif

.include <bsd.obj.mk>

#
# Process 'make obj' recursively (should be declared *after* inclusion
# of bsd.obj.mk)
#
obj:	_PROGSUBDIR

# THE END
