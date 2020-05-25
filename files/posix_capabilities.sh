#!/bin/bash
#A script to collect security information from a Linux host
version="version 1"

report=/tmp/colsecinfo.report"-"`date +"%d-%m-%y"`
export=/tmp
format=$export/colsecinfo-export-`date +"%d-%m-%y"`

header()
{
echo -e "\n\e[00;33m#########################################################\e[00m" 
echo -e "Collect security information from a Linux host" 
echo -e "\e[00;33m#########################################################\e[00m" 
echo -e # $version\n" 
}

binarylist='aria2c\|arp\|ash\|awk\|base64\|bash\|busybox\|cat\|chmod\|chown\|cp\|csh\|curl\|cut\|dash\|date\|dd\|diff\|dmsetup\|docker\|ed\|emacs\|env\|expand\|expect\|file\|find\|flock\|fmt\|fold\|ftp\|gawk\|gdb\|gimp\|git\|grep\|head\|ht\|iftop\|ionice\|ip$\|irb\|jjs\|jq\|jrunscript\|ksh\|ld.so\|ldconfig\|less\|logsave\|lua\|make\|man\|mawk\|more\|mv\|mysql\|nano\|nawk\|nc\|netcat\|nice\|nl\|nmap\|node\|od\|openssl\|perl\|pg\|php\|pic\|pico\|python\|readelf\|rlwrap\|rpm\|rpmquery\|rsync\|ruby\|run-parts\|rvim\|scp\|script\|sed\|setarch\|sftp\|sh\|shuf\|socat\|sort\|sqlite3\|ssh$\|start-stop-daemon\|stdbuf\|strace\|systemctl\|tail\|tar\|taskset\|tclsh\|tee\|telnet\|tftp\|time\|timeout\|ul\|unexpand\|uniq\|unshare\|vi\|vim\|watch\|wget\|wish\|xargs\|xxd\|zip\|zsh'

system_info()
{
echo -e "\e[00;33m### SYSTEM ##############################################\e[00m"

#target hostname info
hostnamed=`hostname 2>/dev/null`
if [ "$hostnamed" ]; then
  echo -e "\e[00;31m[-] Hostname:\e[00m\n$hostnamed"
  echo -e "\n" 
fi

#search all *-release files for version info
release=`cat /etc/*-release 2>/dev/null`
if [ "$release" ]; then
  echo -e "\e[00;31m[-] Specific release information:\e[00m\n$release"
  echo -e "\n" 
fi

}

user_info()
{
echo -e "\e[00;33m### USER/GROUP ##########################################\e[00m" 

#all root accounts (uid 0)
superman=`grep -v -E "^#" /etc/passwd 2>/dev/null| awk -F: '$3 == 0 { print $1}' 2>/dev/null`
if [ "$superman" ]; then
  echo -e "\e[00;31m[-] Super user account(s):\n$superman"
  echo -e "\n"
fi

#pull out vital sudoers info
sudoers=`grep -v -e '^$' /etc/sudoers 2>/dev/null |grep -v "#" 2>/dev/null`
if [ "$sudoers" ]; then
  echo -e "\e[00;31m[-] Sudoers configuration (condensed):$sudoers"
  echo -e "\n"
fi

if [ "$export" ] && [ "$sudoers" ]; then
  mkdir $format/etc-export/ 2>/dev/null
  cp /etc/sudoers $format/etc-export/sudoers 2>/dev/null
fi

#is root permitted to login via ssh
sshrootlogin=`grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | awk '{print  $2}'`
if [ "$sshrootlogin" = "yes" ]; then
  echo -e "\e[00;31m[-] Root is allowed to login via SSH:" ; grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" 
  echo -e "\n"
fi

}

environmental_info()
{
echo -e "\e[00;33m### ENVIRONMENTAL #######################################\e[00m" 

#check if selinux is enabled
sestatus=`sestatus 2>/dev/null`
if [ "$sestatus" ]; then
  echo -e "\e[00;31m[-] SELinux seems to be present:\e[00m\n$sestatus"
  echo -e "\n"
fi

#current umask value with both octal and symbolic output
umaskvalue=`umask -S 2>/dev/null & umask 2>/dev/null`
if [ "$umaskvalue" ]; then
  echo -e "\e[00;31m[-] Current umask value:\e[00m\n$umaskvalue"
  echo -e "\n"
fi

#umask value as in /etc/login.defs
umaskdef=`grep -i "^UMASK" /etc/login.defs 2>/dev/null`
if [ "$umaskdef" ]; then
  echo -e "\e[00;31m[-] umask value as specified in /etc/login.defs:\e[00m\n$umaskdef"
  echo -e "\n"
fi

}

interesting_files()
{
echo -e "\e[00;33m### INTERESTING FILES ####################################\e[00m" 

#search for suid files
allsuid=`find / -perm -4000 -type f 2>/dev/null`
findsuid=`find $allsuid -perm -4000 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$findsuid" ]; then
  echo -e "\e[00;31m[-] SUID files:\e[00m\n$findsuid" 
  echo -e "\n"
fi

if [ "$export" ] && [ "$findsuid" ]; then
  mkdir $format/suid-files/ 2>/dev/null
  for i in $findsuid; do cp $i $format/suid-files/; done 2>/dev/null
fi

#list of 'interesting' suid files
intsuid=`find $allsuid -perm -4000 -type f -exec ls -la {} \; 2>/dev/null | grep -w $binarylist 2>/dev/null`
if [ "$intsuid" ]; then
  echo -e "\e[00;33m[+] Possibly interesting SUID files:\e[00m\n$intsuid" 
  echo -e "\n"
fi

#lists world-writable suid files
wwsuid=`find $allsuid -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsuid" ]; then
  echo -e "\e[00;33m[+] World-writable SUID files:\e[00m\n$wwsuid" 
  echo -e "\n"
fi

#lists world-writable suid files owned by root
wwsuidrt=`find $allsuid -uid 0 -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
if [ "$wwsuidrt" ]; then
  echo -e "\e[00;33m[+] World-writable SUID files owned by root:\e[00m\n$wwsuidrt" 
  echo -e "\n"
fi


}

footer()
{
echo -e "\e[00;33m### SCAN COMPLETE ####################################\e[00m" 
}

call_each()
{
  header
  system_info
  user_info
  environmental_info
  interesting_files
  footer
}

call_each | tee -a $report 2> /dev/null
#EndOfScript