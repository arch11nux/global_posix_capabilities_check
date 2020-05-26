#!/bin/bash
#Posix Capabilities checker
version="version 1"

report=/tmp/global_posix_capabilities_check.report.out
export=/tmp
format=$export/global_posix_capabilities_check-export

header()
{
echo -e "\n\e[00;33m#########################################################\e[00m" 
echo -e "Posix Capabilities checker" 
echo -e "\e[00;33m#########################################################\e[00m" 
echo -e # $version\n" 
}

system_info()
{
echo -e "\e[00;33m### SYSTEM ##############################################\e[00m"

#target hostname info
hostnamed=`hostname 2>/dev/null`
if [ "$hostnamed" ]; then
  echo -e "\e[00;31m[-] Hostname:\e[00m\n$hostnamed"
  echo -e "\n" 
fi

}

interesting_files()
{
echo -e "\e[00;33m### Posix Capabilities FILES ####################################\e[00m" 

#list all files with POSIX capabilities set along with there capabilities
fileswithcaps=`getcap -r / 2>/dev/null | sed 's/=/+/g' | awk -F"+" 'BEGIN {printf "%-30s %-16s %-16s\n", "CAP", "SET", "FILENAME"}{printf "%-30s %-16s %-16s\n", $2,$3,$1}'`
if [ "$fileswithcaps" ]; then
  echo -e "\e[00;31m[+] Files with POSIX capabilities set:\e[00m\n$fileswithcaps"
  echo -e "\n"
fi

if [ "$export" ] && [ "$fileswithcaps" ]; then
  mkdir $format/files_with_capabilities/ 2>/dev/null
  for i in $fileswithcaps; do cp $i $format/files_with_capabilities/; done 2>/dev/null
fi

#searches /etc/security/capability.conf for users associated capapilies
userswithcaps=`grep -v '^#\|none\|^$' /etc/security/capability.conf 2>/dev/null`
if [ "$userswithcaps" ]; then
  echo -e "\e[00;33m[+] Users with specific POSIX capabilities:\e[00m\n$userswithcaps"
  echo -e "\n"
fi

if [ "$userswithcaps" ] ; then
#matches the capabilities found associated with users with the current user
matchedcaps=`echo -e "$userswithcaps" | grep \`whoami\` | awk '{print $1}' 2>/dev/null`
	if [ "$matchedcaps" ]; then
		echo -e "\e[00;33m[+] Capabilities associated with the current user:\e[00m\n$matchedcaps"
		echo -e "\n"
		#matches the files with capapbilities with capabilities associated with the current user
		matchedfiles=`echo -e "$matchedcaps" | while read -r cap ; do echo -e "$fileswithcaps" | grep "$cap" ; done 2>/dev/null`
		if [ "$matchedfiles" ]; then
			echo -e "\e[00;33m[+] Files with the same capabilities associated with the current user (You may want to try abusing those capabilties):\e[00m\n$matchedfiles"
			echo -e "\n"
			#lists the permissions of the files having the same capabilies associated with the current user
			matchedfilesperms=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do ls -la $f ;done 2>/dev/null`
			echo -e "\e[00;33m[+] Permissions of files with the same capabilities associated with the current user:\e[00m\n$matchedfilesperms"
			echo -e "\n"
			if [ "$matchedfilesperms" ]; then
				#checks if any of the files with same capabilities associated with the current user is writable
				writablematchedfiles=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do find $f -writable -exec ls -la {} + ;done 2>/dev/null`
				if [ "$writablematchedfiles" ]; then
					echo -e "\e[00;33m[+] User/Group writable files with the same capabilities associated with the current user:\e[00m\n$writablematchedfiles"
					echo -e "\n"
				fi
			fi
		fi
	fi
fi

}

information()
{
echo -e "\e[00;33m------------------------------------------------------------\e[00m"
echo -e "\e[00;35mThere are 3 modes:"
echo -e " \e[00;35me: Effective = This means the capability is “activated”."
echo -e " \e[00;35mp: Permitted = This means the capability can be used/is allowed."
echo -e " \e[00;35mi: Inherited = The capability is kept by child/subprocesses upon execve() for example."
echo -e "\e[00;33m------------------------------------------------------------\e[00m"
echo -e "--->>> Capabilities blank or empty \e[00;33m( D A N G E R ) <<<---"
echo -e " \e[00;35m Exemple: \e[00;34m/home/user/openssl \e[00;33m =ep"
echo -e "\e[00;33m------------------------------------------------------------\e[00m"

}

footer()
{
echo -e "\e[00;33m### SCAN COMPLETE ####################################\e[00m" 
}

call_each()
{
  header
  system_info
  interesting_files
  information
  footer
}

call_each | tee -a $report 2> /dev/null
#EndOfScript