#!/bin/bash
DB="/etc/smartking4luv/database.sqlite"; DOM=$(cat /etc/smartking4luv/domain 2>/dev/null)
HLINE="\033[0;36m==============================================================\033[0m"
SLINE="\033[0;36m--------------------------------------------------------------\033[0m"

xray_menu() {
  while true; do
    clear; echo -e "$HLINE\n\033[1;37m                 XRAY & SHADOWSOCKS MANAGER                   \033[0m\n$HLINE"
    echo -e "\033[1;32m [1]\033[0m Create Account (Vless/Vmess/Trojan/SS)\n\033[1;32m [2]\033[0m Renew Account\n\033[1;32m [3]\033[0m Delete Account\n$SLINE\n\033[1;31m [0]\033[0m Back to Main Menu\n$HLINE"
    read -p " Select: " opt
    case $opt in
      1) clear; echo -e "$HLINE\n\033[1;37m                 CREATE XRAY ACCOUNT                          \033[0m\n$HLINE"
         read -p " Protocol (vless/vmess/trojan/ss): " pr; read -p " Username: " u; read -p " Days: " d
         id=$(uuidgen); e=$(date -d "+$d days" +"%Y-%m-%d"); sqlite3 $DB "INSERT INTO xray_users VALUES ('$u','$id','$pr','$e');"
         clear; echo -e "$HLINE\n\033[1;32m                 ACCOUNT CREATED SUCCESSFULLY                 \033[0m\n$HLINE"
         echo -e " Username : $u\n UUID     : $id\n Protocol : ${pr^^}\n Expiry   : $e\n$SLINE\n\033[1;33m                      PAYLOAD LINKS                           \033[0m\n$SLINE"
         if [ "$pr" == "vless" ]; then echo -e " \033[1;36m[TLS - 443]\033[0m\n vless://$id@$DOM:443?path=/vmess&security=tls&encryption=none&type=ws#$u\n\n \033[1;36m[Non-TLS - 80]\033[0m\n vless://$id@$DOM:80?path=/vmess&security=none&encryption=none&type=ws#$u"; fi
         if [ "$pr" == "vmess" ]; then echo -e " \033[1;36m[VMess WS]\033[0m\n vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$u\",\"add\":\"$DOM\",\"port\":\"443\",\"id\":\"$id\",\"net\":\"ws\",\"path\":\"/xray\",\"tls\":\"tls\"}" | base64 -w 0)"; fi
         if [ "$pr" == "trojan" ]; then echo -e " \033[1;36m[Trojan TLS]\033[0m\n trojan://$id@$DOM:443?path=/vmess&security=tls&type=ws#$u"; fi
         if [ "$pr" == "ss" ]; then echo -e " \033[1;36m[Shadowsocks SR]\033[0m\n ss://$(echo -n "aes-128-gcm:$id" | base64 -w 0)@$DOM:10005#$u"; fi
         echo -e "$HLINE"; read -p " Press Enter..." ;;
      2) clear; echo -e "$HLINE\n\033[1;37m                 RENEW XRAY ACCOUNT                           \033[0m\n$HLINE\n Active Accounts:"
         sqlite3 $DB "SELECT username, protocol, expiry FROM xray_users;" | column -t -s '|'; echo -e "$SLINE"
         read -p " Username: " u; read -p " Add Days: " d; e=$(date -d "+$d days" +"%Y-%m-%d")
         sqlite3 $DB "UPDATE xray_users SET expiry='$e' WHERE username='$u'"; echo -e "\n \033[1;32m[+] Renewed to $e\033[0m"; read -p " Enter..." ;;
      3) clear; echo -e "$HLINE\n\033[1;37m                 DELETE XRAY ACCOUNT                          \033[0m\n$HLINE\n Active Accounts:"
         sqlite3 $DB "SELECT username, protocol FROM xray_users;" | column -t -s '|'; echo -e "$SLINE"
         read -p " Username: " u; sqlite3 $DB "DELETE FROM xray_users WHERE username='$u'"; echo -e "\n \033[1;31m[-] Deleted\033[0m"; read -p " Enter..." ;;
      0) return ;;
    esac
  done
}
