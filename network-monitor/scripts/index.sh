#!/bin/bash

# Caminhos dos arquivos
relatorio="/network-monitor/output/relatorio.txt"
grafico_traffic="/network-monitor/output/grafico_trafego_traffic.png"
grafico_flows="/network-monitor/output/grafico_trafego_flows.png"
grafico_packets="/network-monitor/output/grafico_trafego_packets.png"
index_html="/network-monitor/output/index.html"

# Função para verificar anomalia (simulação)
check_anomaly() {
    if [[ "$1" == "trafego" ]]; then
        echo "1"  # Anomalia detectada
    else
        echo "0"  # Nenhuma anomalia
    fi
}

# Verificando anomalias
trafego_anomaly=$(check_anomaly "trafego")
flows_anomaly=$(check_anomaly "flows")
packets_anomaly=$(check_anomaly "packets")

# Determina se a classe  deve ser adicionada para cada gráfico
flows_class="verde"
packets_class="verde"
trafego_class="verde"

if [[ "$flows_anomaly" -eq 1 ]]; then
    flows_class="vermelho piscar"
fi

if [[ "$packets_anomaly" -eq 1 ]]; then
    packets_class="vermelho piscar"
fi

if [[ "$trafego_anomaly" -eq 1 ]]; then
    trafego_class="vermelho piscar"
fi

# Criando o conteúdo do arquivo HTML
cat > "$index_html" <<EOL
<!DOCTYPE html>
<html lang="pt-br">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Relatório de Monitoramento</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 0;
            padding: 20px;
            background-color: #f4f4f9;
        }
        .container {
            width: 80%;
            margin: auto;
        }
        .header {
            text-align: center;
            margin-bottom: 20px;
        }
        .content {
            display: flex;
            flex-direction: column;
            align-items: center;
            margin-bottom: 20px;
        }
        .graphs {
            display: flex;
            justify-content: space-around;
            margin-top: 20px;
        }
        .graph-container {
            width: 40%;
        }
        .report {
            width: 90%;
            padding: 15px;
            background-color: white;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            overflow-y: scroll;
            max-height: 300px;
            white-space: pre-wrap;
            font-family: "Courier New", Courier, monospace;
            font-size: 14px;
            line-height: 1.6;
        }
        img {
            width: 100%;
            border-radius: 5px;
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.1);
            cursor: pointer;
            transition: transform 0.3s ease;
        }
        img:active {
            transform: scale(1.5);
        }
        .lampada {
            display: block;
            width: 40px;
            height: 40px;
            border-radius: 50%;
            margin: 10px auto;
            background-color: green;
            cursor: pointer;
            transition: background-color 0.3s ease;
        }
        .lampada.piscar {
            animation: piscar 1s infinite alternate;
        }
        @keyframes piscar {
            0% {
                background-color: red;
            }
            100% {
                background-color: darkred;
            }
        }
    </style>
</head>
<body>

    <div class="container">
        <div class="header">
            <h1>Relatório de Monitoramento</h1>
        </div>

        <div class="content">
            <h2>Conteúdo do Relatório</h2>
            <div class="report">
                $(cat "$relatorio")
            </div>
        </div>

        <div class="graphs">
            <div class="graph-container">
                <h3>Gráfico de Flows</h3>
                <img src="grafico_trafego_flows.png" alt="Gráfico de Flows" class="flows-graph">
                <div class="lampada $flows_class" id="lampada-flows"></div>
            </div>
            <div class="graph-container">
                <h3>Gráfico de Pacotes</h3>
                <img src="grafico_trafego_packets.png" alt="Gráfico de Pacotes" class="packets-graph">
                <div class="lampada $packets_class" id="lampada-packets"></div>
            </div>
            <div class="graph-container">
                <h3>Gráfico de Tráfego</h3>
                <img src="grafico_trafego_traffic.png" alt="Gráfico de Tráfego" class="trafego-graph">
                <div class="lampada $trafego_class" id="lampada-trafego"></div>
            </div>
        </div>
    </div>

    <script>
        // Função para aumentar o tamanho da imagem ao clicar
        const graphs = document.querySelectorAll('img');

        graphs.forEach(graph => {
            graph.addEventListener('click', function() {
                // Alterna o tamanho do gráfico
                if (this.style.transform === 'scale(1.5)') {
                    this.style.transform = 'scale(1)';
                } else {
                    this.style.transform = 'scale(1.5)';
                }
            });
        });

        // Função para alternar entre lâmpada acesa e apagada
        const lamps = document.querySelectorAll('.lampada');

        lamps.forEach(lamp => {
            lamp.addEventListener('click', function() {
                if (this.classList.contains('piscar')) {
                    // Remover o piscar (voltar para verde)
                    this.classList.remove('piscar');
                    this.style.backgroundColor = 'green';
                } else {
                    // Adicionar o piscar (vermelho)
                    this.classList.add('piscar');
                }
            });
        });
    </script>

</body>
</html>
EOL

echo "Arquivo index.html gerado com sucesso em $index_html"


