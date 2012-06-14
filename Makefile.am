
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
dist_myperlmoddisc_DATA = \
	DevDiscover/OneAccess.pm \
	DevDiscover/OneAccess_QoS.pm

myperlmodcoldir = $(perllibdir)/Torrus/Collector
dist_myperlmodcol_DATA = \
	Collector/OneAccess_QoS_Params.pm \
	Collector/OneAccess_QoS.pm


#####   Perl configuration files  #####
torruscfgdir = $(plugtorruscfgdir)
dist_torruscfg_DATA = tp-oneaccess-torruscfg.pl
devdisccfgdir = $(plugdevdisccfgdir)
dist_devdisccfg_DATA = tp-oneaccess-ddcfg.pl



#####   XML configuration   #####
myxmldir = $(distxmldir)/vendor
dist_myxml_DATA = oneaccess.qos.xml


#####   Documentation files   #####
pkgdocdir  = @pkgdocdir@
dist_pkgdoc_DATA = tp-oneaccess.txt tp-oneaccess.pod
SUFFIXES = .pod .txt
.pod.txt:
	pod2text $< $@ 

