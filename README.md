# Zéfiro

Monitor acessível de ritmo respiratório.

## Descrição

Esse projeto foi desenvolvido em 12 horas no primeiro Hackathon da Receita Federal. O desafio era ressignificar os componentes de um cigarro eletrônico para um produto com impacto social. Nossa solução foi o zéfiro (originalmente chamado Breath Sensor, mas "zéfiro" é mais cool). 

O dispositivo consiste em um módulo que se encaixa em um tubo de respiração que monitora o ritmo respiratório de um paciente e envia esse dado em tempo real para um aplicativo (o projeto do app também consta) permitindo que vários pacientes possam ser monitorados simultaneamente.

O sistema é composto por componentes pequenos e de baixo custo, a ideia é justamente uma alternativa acessível e portátil para os dispositivos atualmente presentes no mercado que são grandes e caros.

Acredito que esse projeto tem potencial de ajudar alguém que precisa, se você também acredita, sinta-se livre para contribuir com o projeto ajudando a melhorá-lo, ou mesmo produzindo os módulos para uso próprio.

## Componentes

O módulo é composto por:
1. Carcaça: Impressa em 3d (carcaça.stl)
2. Módulo Esp-8266
3. Microssensor de pressão

## Sistema de comunicação

A placa Esp se conecta ao dispositivo móvel por rede wifi via provisionamento. O app roda um servidor local ao qual o módulo se conecta e envia os pulsos detectados. O aplicativo expõe os dados de respiração enviados pelo módulo em um gráfico. Caso um paciente esteja há um determinado período sem enviar pulsos de respiração, o aplicativo alerta o usuário.

O servidor local é baseado em Flask (biblioteca de python), enquanto o app é escrito em Flutter.

## Limitações

Conexão Wifi

Como no período do hackathon eu só tinha uma placa esp-8662 (que não possui funcionalidade BlueTooth, o sistema ficou limitado a conexões baseadas na mesma rede, o que em casos de comunidades mais economicamente vulneráveis pode nem sempre estar disponível.
Utilizar uma placa esp-32 pode solucionar o problema com a opção de conexão via bluetooth o que limitaria o número de módulos que podem se conectar ao dispositivo móvel os tornando em contrapartida acessíveis em cenários sem redes wifi disponíveis.

Confiabilidade do sensor

Devido ao conceito do evento, utilizamos os microssensores de cigarros eletrônicos para detectar o ritmo respiratório, no entando, por se tratarem de componentes produzidos em massa, esses sensores podem não ser os mais confiáveis podendo levar a falsos positivos (ou pior, falsos negativos). Componentes de sensores mais confiáveis podem serm utilizados, mas o sistema pode demandar uma adaptação.

## Agradecimentos

Gostaria de agradecer ao Cauê Vilela e ao Gabriel Leão que desenvolveram o projeto comigo.

Agradeço também à equipe responsável pelo pitch: Victor Hugo Coutinho, Gustavo de Toledo e João Pedro Okita.

## Conslusão

Esperamos que esse projeto possa fazer alguma diferença no mundo. Mais uma vez reitero que se sintam livres para utilizar o código. No caso de eventuais dúvidas, entre em contato comigo pelo meu email: matheus.cahu@unifesp.br.

