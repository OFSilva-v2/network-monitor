#!/bin/bash

# Ativar saída de debug e imediata em caso de erro
set -e

# Definindo variáveis de log e timestamp
LOG_FILE="/network-monitor/logs/monitoramento.log"
RRD_FILE="/usr/local/var/nfsen/profiles-stat/live/source-core1.rrd"
RRD_OUTPUT_FILE="/network-monitor/output/trafego.rrd"
TIMESTAMP=$(date +%s)

# Função para registrar logs
log_message() {
    local message="$1"
    echo "$message"
    echo "$(date '+%d-%m-%Y / %H:%M:%S') - $message" >> $LOG_FILE
}

# Coletando dados de tráfego das últimas 12 horas
coletar_dados() {
    log_message "Iniciando coleta de dados..."

    # Coletando os dados de tráfego das últimas 12 horas
    # Dados brutos diretamente do arquivo RRD
    dados=$(rrdtool fetch $RRD_FILE AVERAGE --start -43200 --end now)  # 12 horas = 43200 segundos

    # Salvar todos os dados brutos coletados no arquivo de log para análise futura
    echo "$dados" >> /network-monitor/logs/dados_completos.txt
}

# Atualizando arquivo RRD com os dados coletados
atualizar_rrd() {
    log_message "Atualizando arquivo RRD com os dados coletados..."

    # Atualiza o RRD com os dados brutos coletados
    # Não há necessidade de processar ou filtrar, apenas atualizar com os dados brutos
    rrdtool update $RRD_OUTPUT_FILE $dados

    # Verificar se a atualização foi bem-sucedida
    if [ $? -ne 0 ]; then
        log_message "Erro ao atualizar o arquivo RRD com os dados coletados."
        exit 1
    fi

    log_message "Finalizando a atualização."
}

# Iniciando monitoramento
log_message "Iniciando o analisar_metricas.sh..."
bash /network-monitor/scripts/analisar_metricas.sh

log_message "Atualizando os arquivo RRD."
atualizar_rrd

log_message "Monitoramento concluído com sucesso."





