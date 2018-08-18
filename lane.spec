Summary: L'ane - a Point-of-Sale system in Perl
Name: lane
Version: 0.20101024.1
Release: 2
License: GPLv2
Group: Applications/Productivity
Source0: %{name}-%{version}.tgz
Url: http://l-ane.net/
Prefix: /opt
BuildArch: noarch
BuildRoot: /var/tmp/%{name}-buildroot/
#the autorequires can't catch these two since they're indirect
Requires: postgresql-server >= 8.4, perl-DBD-Pg
BuildRequires: perl >= 0:5.008
Vendor: http://l-ane.net/

%description
L'ane is a point-of-sale/service system written in Perl which uses PostgreSQL for storage.

%prep
%setup -n LanePOS

%build
#nothing special to build other than unpacking

%clean 
rm -rf $RPM_BUILD_ROOT

%install
rm -rf $RPM_BUILD_ROOT
#what's the macro name for this? ...or at least /usr/lib/rpm/
/usr/lib/rpm/mkinstalldirs $RPM_BUILD_ROOT/opt
#this requires gnu cp
%__cp -a ../LanePOS $RPM_BUILD_ROOT/opt/

%__rm -f $RPM_BUILD_ROOT/opt/lane.spec

/usr/lib/rpm/mkinstalldirs $RPM_BUILD_ROOT/etc/profile.d
%__mv $RPM_BUILD_ROOT/opt/LanePOS/backOffice/os-integration/laneutils.sh $RPM_BUILD_ROOT/etc/profile.d
%__mv $RPM_BUILD_ROOT/opt/LanePOS/backOffice/os-integration/site.pl $RPM_BUILD_ROOT/opt/LanePOS/config/site.pl

find $RPM_BUILD_ROOT -type f | sed "s#^$RPM_BUILD_ROOT/*#/#" | grep -v '/opt/LanePOS/config' > FilesList
#find $RPM_BUILD_ROOT -type d | sed "s#^$RPM_BUILD_ROOT/*#/#" | grep -v '/opt/LanePOS/config' >> FilesList

#cp a version of site.pl which dies with a message about finishing the install

%files -f FilesList
%defattr(-, root, root)
%attr(-, lanedbadmin, lanedbadmin) %config(noreplace) /opt/LanePOS/config/site.pl
%attr(-, lanedbadmin, lanedbadmin) %dir /opt/LanePOS/config
%attr(-, lanedbadmin, lanedbadmin) /opt/LanePOS/config/site.pl-tests
%attr(-, lanedbadmin, lanedbadmin) /opt/LanePOS/config/README
%attr(-, lanedbadmin, lanedbadmin) /opt/LanePOS/config/init.pl
%attr(-, lanedbadmin, lanedbadmin) /opt/LanePOS/config/sample-site.pl
%dir /opt/LanePOS
%dir /opt/LanePOS/site-perl
%dir /opt/LanePOS/site-perl/lib
%dir /opt/LanePOS/site-perl/lib/Tk
%dir /opt/LanePOS/tests
%dir /opt/LanePOS/tests/register
%dir /opt/LanePOS/tests/register-device-output
%dir /opt/LanePOS/tests/reporter
%dir /opt/LanePOS/register
%dir /opt/LanePOS/register/xmlRegister
%dir /opt/LanePOS/register/common
%dir /opt/LanePOS/register/common/x11
%dir /opt/LanePOS/register/tester
%dir /opt/LanePOS/register/curses
%dir /opt/LanePOS/dataset
%dir /opt/LanePOS/dataset/v1to2
%dir /opt/LanePOS/dataset/v2to3
%dir /opt/LanePOS/dataset/locale-datasets
%dir /opt/LanePOS/backOffice
%dir /opt/LanePOS/backOffice/xmlReporter
%dir /opt/LanePOS/backOffice/tkOffice
%dir /opt/LanePOS/backOffice/utilities
%dir /opt/LanePOS/backOffice/reports
%dir /opt/LanePOS/backOffice/os-integration
%dir /opt/LanePOS/LanePOS
%dir /opt/LanePOS/LanePOS/Dal
%dir /opt/LanePOS/LanePOS/Devices
%dir /opt/LanePOS/LanePOS/Devices/Epson
%dir /opt/LanePOS/LanePOS/Devices/BurrellBizSys
%dir /opt/LanePOS/LanePOS/Devices/Ryotous
#/opt/LanePOS/

%post
sed -i -e "s#/opt#$RPM_INSTALL_PREFIX#" /etc/profile.d/laneutils.sh

%pre
#export >&2

PATH=$PATH:/sbin:/usr/sbin
export PATH

#only do these things the first time
#if [ $1 == 1 ];
#there was a bug in previous versions of the rpm, so now, actually check to see if the user exists
if [ "`getent passwd lanedbadmin`" = "" ];
then
        useradd -c "L'ane DB Admin" -r -m lanedbadmin
        #make sure postgresql is running before we try to access it
        if [ "`pidof postmaster`" = "" ];
        then
                service postgresql start
        fi
        su - postgres -c 'createuser --superuser lanedbadmin' || ( userdel --remove lanedbadmin && false )
fi

%postun
PATH=$PATH:/sbin:/usr/sbin
export PATH

#only remove the user if we're not updating
if [ $1 == 0 ];
then
        if [ "`pidof postmaster`" = "" ];
        then
                service postgresql start
        fi
        su - postgres -c 'dropuser lanedbadmin' && userdel --remove lanedbadmin
fi

%changelog
* Sun Apr 17 2011 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20101024.1-2
- Release tag: http://tasks.l-ane.net/showdependencytree.cgi?id=1413
- built for new release
- just includes updates to support YUM

* Sun Oct 24 2010 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20101024.0-1
- Release tag: http://tasks.l-ane.net/showdependencytree.cgi?id=1357
- built for new release

* Thu Oct 14 2010 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20100926.1-1
- Release tag: http://tasks.l-ane.net/showdependencytree.cgi?id=1381
- built for new release

* Sun Sep 26 2010 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20100926.0-1
- Release tag: http://tasks.l-ane.net/showdependencytree.cgi?id=1331
- built for new release
- add a Tk error message to the unconfigured site.pl
- allow for relocations

* Mon Oct 10 2005 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20050314-1
- corrected to "noarch"

* Mon Oct 10 2005 Jason Burrell <jburrellatusersdotsfdotnet> - 0.20050314-0
- Built successfully
