# IITG Fortinet Firewall Authentication Script For linux (Version: 4)
# ==================================================================
# The authentication  script  has  been  redesigned  based  on  the 
# IITG  Fortinet  Firewall  specification and it's  login workflow, 
# to meet  the  requirement. This  script  allows  users  to  login 
# to  the  IITG  Fortinet Firewall from the  command line  and  get 
# connected (via keep alive mode) until  explicitly  stop/exit (Ctrl+C)
# from the script. In this version of the script, user has to explicitly 
# specify his/her username and password(used for internet accesing) 
# in the standard input.

#  If you have some system proxy defined,then please disable that one.

#  * Dependency is the "bash" shell and "curl" which most of the linux 
#    system has by default.

#  * Give execute permission to the script
#    chmod 755 iitgnetauth.sh
#    You can also give only root to have read/write/execute permission

#  * Make sure that your /tmp/temp.html file writable by the user

#  * Run the executable
#    ./iitgnetauth.sh

#  * While running, the script will prompted for username and password
#    enter username: (username used for internet access)
#    enter password: (password used for internet access)

#  * Auto login feature available in this script to keep 
#    the login session active

#  (Developed and Re-designed by: Sanjoy Das,CCC, IITG)
 
#  Permission is hereby granted, free of charge, to any person obtaining a copy
#  of this software and associated documentation files (the "Software"), to deal
#  in the Software without restriction, including without limitation the rights
#  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#  copies of the Software, and to permit persons to whom the Software is
#  furnished to do so, subject to the following conditions:

#  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#  SOFTWARE.



#!/bin/bash

url="https://agnigarh.iitg.ac.in:1442/logout?"
req_url="${url:0:33}";

rm /tmp/temp.html  > /dev/null 2>&1;

#trap '(echo "Exiting....." && echo "Logged Out" && curl  -k -o /tmp/temp.html "$url"  > /dev/null 2>&1 ); exit 0;' SIGINT
trap '(echo "Exiting....." && echo "Logged Out" && ps -ef | grep "iitgnetauth" | grep -v grep | awk "{print $2}" | xargs -r kill -9  && curl  -k -o /tmp/temp.html "$url"  > /dev/null 2>&1 ); exit 0;' SIGINT

while true; do	
	if [ -z  $logged ]; then
		#user=""; # Specify username here
		#pass=""; # Specify password here
		echo -n "Enter Username:";
                read  user;
                echo -n "Enter Password:";
                read -s pass;
                echo "";
  	fi	

	# Checking login parameter validation
	if [ -z  $user ]; then
		echo "Please specify username !!";
		exit 1;	
	fi
	if [ -z  $pass ]; then
		echo "Please specify password !!";
		exit 1;	
	fi

        re_url=$(curl -Lsk -o /dev/null -w %{url_effective} $url);
        #echo "redirect url: $re_url";

	until $(curl  -k -o /tmp/temp.html "$re_url"  > /dev/null 2>&1); do 
		echo "Connecting.....";
		sleep 5;
	done
	echo "Connected.....";

	magic=$(cat /tmp/temp.html | grep -o "magic.*>" | grep -o "=.*>" |tr -d '\">=');
	#echo "Magic Value: $magic";      	

	tredir=$(cat /tmp/temp.html | grep -o "4Tredir.*>" | grep -o "=.*>" |tr -d '\">=');
	#echo "4Tredir Value: $tredir";      	

	until $(curl -k -L -o /tmp/temp.html -d "4Tredir=$tredir" -d "username=$user" -d 'submit=Continue' -d "password=$pass" -d "magic=$magic" "$req_url"  > /dev/null 2>&1); do 
		echo "Logging In.....";	
	done

	ka_url=$(cat /tmp/temp.html | grep -o "location.href=.*;" | grep -o "\"[^\"]*\"" | head -n1  | tr -d '"' );	
	#echo "KeepAlive URL Value: $ka_url";


	if [ ! -z  $ka_url ]; then
		echo "Logged In";
      		logged="1";
	else
		echo "Login Failed";
		continue;
  	fi

	while true; do
		sleep 110; # after every 110 second, active the keep alive session
		if $(curl -k -o /tmp/temp.html $ka_url  > /dev/null 2>&1); then
      			echo "Keeping.....Alive";
			continue;
  		fi
		break;
    	done

done
