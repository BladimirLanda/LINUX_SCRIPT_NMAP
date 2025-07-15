#!/bin/bash

#Este programa parsea los resultado de nmap y construye un archivo html

##contantes
TITULO="Resultado nmap"
FECHA_ACTUAL="$(date)"
TIMESTAMP="Informe generado el $FECHA_ACTUAL por el usuario $USERNAME"

##funciones
nmap_exec () {
    echo "[INFO] executando nmap para la red $1, por favor espere unos segundos..."
    sudo nmap -sV $1 > $2
    echo "[OK] fichero $2 generado correctamente!!"
    return 0
}

nmap_gener () {
    ##general el reporte raw con nmap                                                                                                                                   
    nmap_exec "192.168.19.0/24" "salida_nmap.raw"                                                                                                                            
    ##Dividr el archivo por linea vacias                                                                                                                                     
    echo "[INFO] diviendo el archivo salida_nmap.raw"                                                                                                                        
    csplit -f parte_ salida_nmap.raw '/^$/' '{*}' > /dev/null                                                                                                                
    echo "[OK] fichero salida_nmap.raw dividio en los siguientes ficheros: $(ls parte_*)" 
	return 0
}

result_parser () {
    for i in parte_*; do                                                                                                                                          
	host_ip=$(grep -E "Nmap scan report " $i | grep -o -E "[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}")
	if [ $host_ip ]; then
            ports_open=$(grep -h -E "^[0-9]{1,5}/(tcp|udp) open" $i | grep -o -E "^[0-9]{1,5}/(tcp|udp)")
	    servers=$(grep -h -E "^[0-9]{1,5}/(tcp|udp) open" $i | grep -o -E "  [a-z0-9?+-]{2,10}" | tr -d ' ')
	    
	    echo "<tr>"                                                                                                                                          
	      echo "<td>$host_ip</td>"
              if [ $ports_open ]; then
		  echo "<td>$ports_open</td>"
		  echo "<td>$servers</td>"
	      else
		  echo "<td>No hay puertos abiertos</td>"
		  echo "<td>------</td>"
	      fi                                                                                                                     
	    echo "</tr>"                                                                                                                                         
	fi                                                                                                                                                       
    done
	return 0   
}

generar_html () {
cat <<EOF
    <html>
	<head>
		<title>$TITULO</title>
	     	<style>
			table {
 		      	 font-family: arial, sans-serif;
  			 border-collapse: collapse;
  			 width: 100%;
			}

			td, th {
 			 border: 1px solid #dddddd;
  			 text-align: left;
  			 padding: 8px;
			}

		       tr:nth-child(even) {
  			background-color: #dddddd;
		       }
	 	</style>
	</head>
	
	<body>
		<h1>$TITULO</h1>
	      	<p>$TIMESTAMP</p>

		<table>
			<tr>
				<th>HOST IP</th>
				<th>Puertos Abiertos</th>
				<th>Servicio</th>
			</tr>
			
			$(result_parser)
	     	</table>
	</body>	
    </html>
EOF
}

##condición
if [ $(find salida_nmap.raw -mmin -30) ];then
    while true; do
	read -p "Exite el fichero salida_nmap.raw con antiguedad menor a 30min. ¿Sobreescribir? [y/n]:" res
	if [ $res = y ]; then
	    nmap_gener
	    break
	elif [ $res = n ]; then
	    echo "[INFO] Utilizando el fichero salida_nmap.raw existente"
	    break
	fi
    done
else
    nmap_gener
fi

##plasmar los resultados del reporte en el HTML
echo "[INFO] generando reporte html..."
generar_html > resultado_nmap.html
echo "[OK] reporte resultados_nmap.html generado correctamente!!"
