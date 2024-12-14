#!/bin/bash

# Configuração do destinatário e do assunto do e-mail
EMAIL_DESTINATARIO="xxxxxxx@gmail.com"
ASSUNTO="Alerta de Tráfego Anômalo"
CORPO_EMAIL="Detectamos tráfego anômalo no sistema.\n\nSegue o relatório de alerta:\n\n"

# Caminho para o arquivo de alerta
ARQUIVO_ALERTA="/network-monitor/output/relatorio.txt"

# Configuração do servidor SMTP (exemplo com Gmail)
SMTP_SERVER="smtp.gmail.com"
SMTP_PORT="587"
SMTP_USUARIO="xxxxxxxx@gmail.com"
SMTP_SENHA="${SMTP_SENHA:-"xxxxxxxxx"}"  # Use variável de ambiente SMTP_SENHA ou valor padrão

# Verifica se o arquivo de alerta existe e não está vazio
if [[ ! -f "$ARQUIVO_ALERTA" || ! -s "$ARQUIVO_ALERTA" ]]; then
    echo "Erro: O arquivo de alerta $ARQUIVO_ALERTA não foi encontrado ou está vazio."
    exit 1
fi

# Verificar se o comando swaks está instalado
if ! command -v swaks &> /dev/null; then
    echo "Erro: O comando 'swaks' não está instalado. Instale-o para enviar e-mails."
    exit 1
fi

# Adiciona o link ao corpo do e-mail
CORPO_EMAIL+="\n\nPara acessar o relatório completo e visualizar os gráficos, clique no link abaixo:\n"
CORPO_EMAIL+=" http://200.132.0.126:8080/index.html \n"

# Lê o conteúdo do arquivo de alerta e adiciona ao corpo do e-mail
CORPO_EMAIL+=$(cat "$ARQUIVO_ALERTA")

# Enviar e-mail com Swaks
echo "Enviando e-mail para $EMAIL_DESTINATARIO..."
echo -e "$CORPO_EMAIL" | swaks --to "$EMAIL_DESTINATARIO" \
      --from "$SMTP_USUARIO" \
      --header "Subject: $ASSUNTO" \
      --body - \
      --server "$SMTP_SERVER" \
      --port "$SMTP_PORT" \
      --auth LOGIN \
      --auth-user "$SMTP_USUARIO" \
      --auth-password "$SMTP_SENHA" \
      --tls

# Verificar o sucesso do envio
if [[ $? -eq 0 ]]; then
    echo "E-mail enviado com sucesso para $EMAIL_DESTINATARIO."
else
    echo "Falha no envio do e-mail."
    exit 1
fi


