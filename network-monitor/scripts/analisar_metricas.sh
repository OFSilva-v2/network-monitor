#!/bin/bash

# Ativar saída de debug e imediata em caso de erro
set -e

# Caminhos de arquivos e diretórios
RRD_FILE="/usr/local/var/nfsen/profiles-stat/live/source-core1.rrd"
OUTPUT_DIR="/network-monitor/output"

# Arquivos de saída
REPORT_FILE="$OUTPUT_DIR/relatorio.txt"
GRAPH_PACKETS_FILE="$OUTPUT_DIR/grafico_trafego_packets.png"
GRAPH_FLOWS_FILE="$OUTPUT_DIR/grafico_trafego_flows.png"
GRAPH_TRAFFIC_FILE="$OUTPUT_DIR/grafico_trafego_traffic.png"


# Variáveis de data e hora
data=$(date "+%d-%m-%Y")
hora=$(date "+%H:%M:%S")
log="/network-monitor/logs/analisar_metricas.log"
email_script="/network-monitor/scripts/enviar_email.sh"
relatorio="/network-monitor/output/relatorio.txt"

# Arquivo RRD
rrd_file="/network-monitor/output/trafego.rrd"

# Função para registrar as mensagens no log
log_message() {
    echo "$(date "+%d-%m-%Y / %H:%M:%S") - $1" | tee -a $log
}

# Iniciando a análise
log_message "Iniciando análise dos dados..."

# Função para converter valores numéricos para unidades legíveis
convert_units() {
    value=$1
    if [[ -z "$value" || "$value" == "-nan" ]]; then
        echo "0 "
        return
    fi
    if (( $(echo "$value < 1024" | bc -l) )); then
        echo "${value} "
    elif (( $(echo "$value < 1048576" | bc -l) )); then
        echo "$(echo "scale=2; $value / 1024" | bc) "
    else
        echo "$(echo "scale=2; $value / 1048576" | bc) "
    fi
}

# Inicializando arrays
timestamps=()
flows=()
packets=()
traffics=()
horarios=()

# Obter dados usando rrdtool fetch
dados=$(rrdtool fetch "$RRD_FILE" AVERAGE --start -1200 --end now)

# Processar os dados
while read -r linha; do
    # Ignorar cabeçalhos e linhas vazias
    [[ "$linha" =~ ^([0-9]+): ]] || continue
    timestamp=${BASH_REMATCH[1]}
    horario=$(date -d @"$timestamp" "+%H:%M:%S")

    # Separar valores das métricas
    valores=($linha)
    flow_tcp=$(echo "${valores[1]}" | awk '{printf "%.1f", $1}')
    flow_udp=$(echo "${valores[2]}" | awk '{printf "%.1f", $1}')
    flow_icmp=$(echo "${valores[3]}" | awk '{printf "%.1f", $1}')
    flow_other=$(echo "${valores[4]}" | awk '{printf "%.1f", $1}')
    packet_tcp=$(echo "${valores[5]}" | awk '{printf "%.1f", $1}')
    packet_udp=$(echo "${valores[6]}" | awk '{printf "%.1f", $1}')
    packet_icmp=$(echo "${valores[7]}" | awk '{printf "%.1f", $1}')
    packet_other=$(echo "${valores[8]}" | awk '{printf "%.1f", $1}')
    traffic_tcp=$(echo "${valores[9]}" | awk '{printf "%.1f", $1}')
    traffic_udp=$(echo "${valores[10]}" | awk '{printf "%.1f", $1}')
    traffic_icmp=$(echo "${valores[11]}" | awk '{printf "%.1f", $1}')
    traffic_other=$(echo "${valores[12]}" | awk '{printf "%.1f", $1}')

    # Calcular os totais de Fluxos, Pacotes e Tráfego
    # Certificar-se de que cada valor de fluxo e pacote seja somado corretamente
    flows_all=$(echo "scale=2; ($flow_tcp + $flow_udp + $flow_icmp + $flow_other) / 2" | bc)
    packets_all=$(echo "($packet_tcp + $packet_udp + $packet_icmp + $packet_other)/2" | bc)
    traffic_total=$(echo "scale=2; ($traffic_tcp + $traffic_udp + $traffic_icmp + $traffic_udp) / 1000000 * 8" | bc)

    # Verifica se os valores extraídos são numéricos e válidos
    if [[ "$flows_all" =~ ^[0-9]+(\.[0-9]+)?$ && "$packets_all" =~ ^[0-9]+(\.[0-9]+)?$ && "$traffic_total" =~ ^[0-9]+(\.>
        timestamps+=("$timestamp")
        flows+=("$flows_all")
        packets+=("$packets_all")
        traffics+=("$traffic_total")
        horarios+=("$horario")
    else
        echo "Valores inválidos ignorados: $linha"
    fi
done <<< "$dados"

# Verificar se há dados suficientes
if [[ ${#horarios[@]} -eq 0 ]]; then
    log_message "Nenhum dado válido encontrado nos últimos 15 minutos."
    exit 1
fi


# Gerando relatório em formato de tabela
log_message "Gerando relatório..."
{
    echo "Relatório de Monitoramento - $data"
    echo ""
    echo "Métricas Coletadas"
    echo ""
    printf "%-10s %-20s %-20s %-20s\n" "Horário" "Fluxos f/s" "Pacotes p/s" "Tráfego Mb/s"
    for i in "${!horarios[@]}"; do
        # Conversão dos valores para unidades legíveis para exibição na tabela
        human_flows=$(convert_units "${flows[i]}")
        human_packets=$(convert_units "${packets[i]}")
        human_traffic=$(convert_units "${traffics[i]}")

        printf "%-10s %-20s %-20s %-20s\n" "${horarios[i]}" "$human_flows " "$human_packets " "$human_traffic "
    done

    echo ""
    echo "Anomalias Detectadas"

} > "$relatorio"

log_message "Relatório gerado com sucesso."

# Gerando gráficos para as métricas
log_message "Gerando gráficos..."

# Gera gráficos

rrdtool graph "$GRAPH_PACKETS_FILE" \
    --title "Pacotes (últimas 12 horas)" \
    --width 1000 --height 500 \
    --start end-12h --end now \
    DEF:packets="$RRD_FILE":packets:AVERAGE \
    AREA:packets#030985:"Pacotes"

rrdtool graph "$GRAPH_FLOWS_FILE" \
    --title "Fluxos (últimas 12 horas)" \
    --width 1000 --height 500 \
    --start end-12h --end now \
    DEF:flows="$RRD_FILE":flows:AVERAGE \
    AREA:flows#055418:"Fluxos"

rrdtool graph "$GRAPH_TRAFFIC_FILE" \
    --title "Tráfego (últimas 12 horas)" \
    --width 1000 --height 500 \
    --start end-12h --end now \
    DEF:traffic="$RRD_FILE":traffic:AVERAGE \
    AREA:traffic#910909:"Tráfego"


echo "Gráficos gerados com sucesso!"

# Verificando anomalias para Fluxos, Pacotes e Tráfego
anomalia_detectada=0

# Calculando limiar de anomalia (75% acima do valor inicial para cada métrica)
limiar_fluxo=$(echo "${flows[0]} * 1.75" | bc)
limiar_pacote=$(echo "${packets[0]} * 1.75" | bc)
limiar_trafego=$(echo "${traffics[0]} * 1.75" | bc)

# Comparando cada métrica com o limiar
for i in "${!flows[@]}"; do
    if (( $(echo "${flows[i]} > $limiar_fluxo" | bc -l) )); then
        echo "Anomalia de Fluxo detectada em ${horarios[i]} (Valor bruto: ${flows[i]} Limite: $limiar_fluxo)" >> $relato>
        anomalia_detectada=1
    fi
    if (( $(echo "${packets[i]} > $limiar_pacote" | bc -l) )); then
        echo "Anomalia de Pacote detectada em ${horarios[i]} (Valor bruto: ${packets[i]} Limite: $limiar_pacote)" >> $re>
        anomalia_detectada=1
    fi
    if (( $(echo "${traffics[i]} > $limiar_trafego" | bc -l) )); then
        echo "Anomalia de Tráfego detectada em ${horarios[i]} (Valor bruto: ${traffics[i]} Limite: $limiar_trafego)" >> >
        anomalia_detectada=1
    fi
done

# Enviar e-mail caso haja anomalia
if [[ $anomalia_detectada -eq 1 ]]; then
    log_message "Anomalia detectada. Enviando relatório por e-mail..."
    bash "$email_script" "$relatorio"
else
    log_message "Nenhuma anomalia detectada."
fi

log_message "Análise concluída com sucesso."

# Acionar o script index.sh
log_message "Acionando o script index.sh..."
bash /network-monitor/scripts/index.sh

log_message "Index.sh acionado com sucesso."

