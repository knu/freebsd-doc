#
# $FreeBSD$
#
#
# This include file <doc.install.mk> provides variables defining the default
# ownership, location, and installation method of files generated by the 
# FreeBSD Documentation Project
#
# Since users often build and install documentation without root,
# default the document ownership to them, if they're not root.
#

# ------------------------------------------------------------------------
#
# Document-specific variables:
#
#	NONE
#

# ------------------------------------------------------------------------
#
# User-modifiable variables:
#
#	INSTALL_DOCS	The command to use to install the documentation.
#			Defaults to "install -o user -g group -m 444",
#			roughly.  
#
#			Should honour DOCOWN, DOCGRP and DOCMODE.
#
#			Should accept a list of files to install
#			followed by the directory to install into.
#
#	INSTALL_FLAGS	Flags to pass to the default INSTALL_DOCS
#			install command.  Useful options are [CdDp].
#			See install(1) for more information.
#
#	DOCDIR		Where to install the documentation.  Default is
#			/usr/share/doc.
#
#	DOCOWN		Owner of the documents when installed.  Forced
#			to the user installing the documentation, if the
#			user is not root. (for obvious reasons)
#
#	DOCGRP		Group of the documents when installed.  Forced
#			to the primary group of the documentation, if
#			the user is not root.  This action can be
#			overriden by setting:
#
#	DOCGRP_OVERRIDE Override the use of primary group when the user
#			installing is not root.  Sets DOCGRP to this
#			instead.
#
#	DOCMODE		Mode of the documents when installed.  Defaults
#			to 444.  See chmod(1).
#
#	PACKAGES	Directory in which to put packages.  Defaults to
#			the packages directory under DOC_PREFIX, if it
#			exists, else the current directory.
#

# ------------------------------------------------------------------------
#
# Make files included (if NOINCLUDEMK is not set):
# 
# 	bsd.own.mk	Default permissions and locations for install.
#

# Include system defaults, unless prevented.
.if !defined(NOINCLUDEMK)
.include <bsd.own.mk>
.endif

DOCOWN?=	root
DOCGRP?=	wheel

DOCMODE?=	0444

DOCDIR?=	/usr/share/doc

.if exists(${DOC_PREFIX}/packages)
PACKAGES?=	${DOC_PREFIX}/packages
.else
PACKAGES?=	${.OBJDIR}
.endif

# hack to set DOCOWN and DOCGRP to those of the user installing, if that
# user is not root.

USERID!=	id -u
USERNAME!=	id -un
GROUPNAME!=	id -gn

.if ${USERID} != 0
DOCOWN:=	${USERNAME}
.if defined(DOCGRP_OVERRIDE)
DOCGRP:=	${DOCGRP_OVERRIDE}
.else
DOCGRP:=	${GROUPNAME}
.endif
.endif

COPY?=	-C

# installation "script"
INSTALL_DOCS?= \
	${INSTALL} ${COPY} ${INSTALL_FLAGS} -o ${DOCOWN} -g ${DOCGRP} -m ${DOCMODE}

# ------------------------------------------------------------------------
#
# Work out the language and encoding used for this document.
#
# Liberal default of maximum of 10 directories below to find it.
#

DOC_PREFIX_NAME?=	doc

.if !defined(LANGCODE)
LANGCODE:=	${.CURDIR}
.for _ in 1 2 3 4 5 6 7 8 9 10
.if !(${LANGCODE:H:T} == ${DOC_PREFIX_NAME})
LANGCODE:=	${LANGCODE:H}
.endif
.endfor
LANGCODE:=	${LANGCODE:T}
.endif
