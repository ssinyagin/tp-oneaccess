
#  Copyright (C) 2002  Stanislav Sinyagin
#
#  This program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

# $Id: Makefile.am,v 1.2 2007/01/23 16:57:51 ssinyagin Exp $
# 
#

# Torrus plugin Automake script


#####   Perl modules  #####
myperlmoddiscdir = $(perllibdir)/Torrus/DevDiscover
dist_myperlmoddisc_DATA = DevDiscover/OneOS_cbQoS.pm

myperlmodcoldir = $(perllibdir)/Torrus/Collector
dist_myperlmodcol_DATA = \
	Collector/OneOS_cbQoS.pm \
	Collector/OneOS_cbQoS_Params.pm


#####   Perl configuration files  #####
torruscfgdir = $(plugtorruscfgdir)
dist_torruscfg_DATA = oneaccess-cbqos-torruscfg.pl
devdisccfgdir = $(plugdevdisccfgdir)
dist_devdisccfg_DATA = oneaccess-cbqos-ddcfg.pl



#####   XML configuration   #####
myxmldir = $(distxmldir)/vendor
dist_myxml_DATA = oneaccess.oneos.cbqos.xml


#####   Documentation files   #####
pkgdocdir  = @pkgdocdir@
dist_pkgdoc_DATA = tp-oneaccess-cbqos.txt
